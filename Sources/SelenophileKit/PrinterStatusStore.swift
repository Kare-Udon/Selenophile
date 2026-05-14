import Foundation
import Observation

public struct MoonrakerRetryPolicy: Sendable {
    public var maxAttempts: Int
    public var delay: @Sendable (_ attempt: Int) -> Duration

    public init(
        maxAttempts: Int = 3,
        delay: @escaping @Sendable (_ attempt: Int) -> Duration = { attempt in
            Self.defaultDelay(attempt: attempt)
        }
    ) {
        self.maxAttempts = maxAttempts
        self.delay = delay
    }

    public static func defaultDelay(attempt: Int) -> Duration {
        switch attempt {
        case 1:
            return .seconds(2)
        case 2:
            return .seconds(4)
        default:
            return .seconds(8)
        }
    }
}

public enum MoonrakerConnectionState: Equatable, Sendable {
    case unconfigured
    case connecting
    case connected
    case reconnecting
    case disconnected
    case failed

    public var localizedLabel: String {
        localizedLabel(language: .simplifiedChinese)
    }

    public func localizedLabel(language: AppLanguage) -> String {
        switch self {
        case .unconfigured:
            return AppLocalization.localizedString(.menuConnectionBadgeUnconfigured, language: language)
        case .connecting:
            return AppLocalization.localizedString(.menuConnectionBadgeConnecting, language: language)
        case .connected:
            return AppLocalization.localizedString(.menuConnectionBadgeConnected, language: language)
        case .reconnecting:
            return AppLocalization.localizedString(.menuConnectionBadgeRetrying, language: language)
        case .disconnected:
            return AppLocalization.localizedString(.menuConnectionBadgeDisconnected, language: language)
        case .failed:
            return AppLocalization.localizedString(.menuConnectionBadgeFailed, language: language)
        }
    }
}

public protocol MoonrakerConfigurationPersisting {
    func load() -> MoonrakerConfiguration?
    func save(_ configuration: MoonrakerConfiguration)
    func clear()
}

public final class UserDefaultsMoonrakerConfigurationStore: MoonrakerConfigurationPersisting {
    private let defaults: UserDefaults
    private let credentialStore: any MoonrakerCredentialStoring
    private let key = "moonraker.configuration"

    public init(
        defaults: UserDefaults = .standard,
        credentialStore: any MoonrakerCredentialStoring = KeychainMoonrakerCredentialStore()
    ) {
        self.defaults = defaults
        self.credentialStore = credentialStore
    }

    public func load() -> MoonrakerConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let configuration = try? JSONDecoder().decode(MoonrakerConfiguration.self, from: data) else {
            return nil
        }

        if let legacyToken = configuration.apiToken {
            if credentialStore.saveAPIToken(legacyToken) {
                persistUserDefaultsConfiguration(configurationWithoutAPIToken(configuration))
            }
            return configuration
        }

        guard let token = credentialStore.loadAPIToken() else {
            return configuration
        }
        return replacingAPIToken(in: configuration, with: token)
    }

    public func save(_ configuration: MoonrakerConfiguration) {
        _ = credentialStore.saveAPIToken(configuration.apiToken)
        persistUserDefaultsConfiguration(configurationWithoutAPIToken(configuration))
    }

    public func clear() {
        defaults.removeObject(forKey: key)
        credentialStore.clearAPIToken()
    }

    private func persistUserDefaultsConfiguration(_ configuration: MoonrakerConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: key)
    }

    private func configurationWithoutAPIToken(_ configuration: MoonrakerConfiguration) -> MoonrakerConfiguration {
        replacingAPIToken(in: configuration, with: nil)
    }

    private func replacingAPIToken(
        in configuration: MoonrakerConfiguration,
        with apiToken: String?
    ) -> MoonrakerConfiguration {
        MoonrakerConfiguration(
            serverURLString: configuration.serverURLString,
            apiToken: apiToken,
            cameraSnapshotURL: configuration.cameraSnapshotURL,
            appLanguage: configuration.appLanguage
        )
    }
}

@MainActor
@Observable
public final class PrinterStatusStore {
    public var configuration: MoonrakerConfiguration? {
        didSet {
            onConfigurationChange?(configuration)
        }
    }
    public var connectionState: MoonrakerConnectionState = .unconfigured
    public var printerStatus = PrinterStatus()
    public var statusRefreshPolicy: PrinterStatusRefreshPolicy {
        didSet {
            statusRefreshPolicyPersistence.save(statusRefreshPolicy)
            publishLatestStatus()
        }
    }
    public var lastErrorMessage: String?
    public var lastUpdatedAt: Date?
    public var onWidgetSnapshotChange: ((WidgetSnapshot) -> Void)?
    public var onConfigurationChange: ((MoonrakerConfiguration?) -> Void)?
    public private(set) var cameraSnapshotData: Data?
    public private(set) var cameraSnapshotUpdatedAt: Date?
    public private(set) var cameraSnapshotErrorMessage: String?
    public private(set) var isFetchingCameraSnapshot = false
    public private(set) var currentPrintThumbnailData: Data?
    public private(set) var currentPrintThumbnailErrorMessage: String?
    public private(set) var isFetchingCurrentPrintThumbnail = false
    public private(set) var isWaitingForManualCurrentPrintThumbnailRetry = false
    public private(set) var retryAttemptCount = 0
    public private(set) var nextRetryAt: Date?
    public private(set) var isWaitingForManualReconnect = false

    private let logStore: AppLogStore?
    private let client: MoonrakerClientProtocol
    private let cameraClient: MoonrakerCameraClientProtocol
    private let persistence: MoonrakerConfigurationPersisting
    private let statusRefreshPolicyPersistence: any PrinterStatusRefreshPolicyPersisting
    private let retryPolicy: MoonrakerRetryPolicy
    private let currentPrintThumbnailRetryLimit: Int
    private let sleep: @Sendable (Duration) async -> Void
    private var connectTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var metadataFetchTask: Task<Void, Never>?
    private var metadataFetchFilename: String?
    private var metadataFetchToken: UUID?
    private var metadataRescanFilename: String?
    private var currentPrintThumbnailRetryCount: Int = 0
    private var isDisconnectingIntentionally = false
    @ObservationIgnored private var livePrinterStatus = PrinterStatus()
    @ObservationIgnored private var liveLastUpdatedAt: Date?
    @ObservationIgnored private var statusPublishTask: Task<Void, Never>?
    @ObservationIgnored private var lastStatusPublishedAt: Date?

    public init(
        client: MoonrakerClientProtocol = MoonrakerClient(),
        cameraClient: MoonrakerCameraClientProtocol = MoonrakerCameraClient(),
        persistence: MoonrakerConfigurationPersisting = UserDefaultsMoonrakerConfigurationStore(),
        statusRefreshPolicy: PrinterStatusRefreshPolicy? = nil,
        statusRefreshPolicyPersistence: any PrinterStatusRefreshPolicyPersisting = UserDefaultsPrinterStatusRefreshPolicyStore(),
        retryPolicy: MoonrakerRetryPolicy = MoonrakerRetryPolicy(),
        currentPrintThumbnailRetryLimit: Int = 3,
        sleep: @escaping @Sendable (Duration) async -> Void = { duration in
            try? await Task.sleep(for: duration)
        },
        logStore: AppLogStore? = nil
    ) {
        self.logStore = logStore
        self.client = client
        self.cameraClient = cameraClient
        self.persistence = persistence
        self.statusRefreshPolicyPersistence = statusRefreshPolicyPersistence
        self.statusRefreshPolicy = statusRefreshPolicy ?? statusRefreshPolicyPersistence.load()
        self.retryPolicy = retryPolicy
        self.currentPrintThumbnailRetryLimit = currentPrintThumbnailRetryLimit
        self.sleep = sleep
        self.configuration = persistence.load()
    }

    public var needsInitialConfiguration: Bool {
        configuration == nil
    }

    public var hasActivePrint: Bool {
        printerStatus.state == .printing || printerStatus.state == .paused
    }

    public var cameraSnapshotURL: String? {
        configuration?.cameraSnapshotURL
    }

    public var canManuallyRetryCurrentPrintThumbnail: Bool {
        guard configuration != nil else { return false }
        guard let filename = printerStatus.filename?.trimmingCharacters(in: .whitespacesAndNewlines),
              !filename.isEmpty
        else {
            return false
        }
        return !isFetchingCurrentPrintThumbnail && currentPrintThumbnailData == nil
    }

    public var connectionBadgeLabel: String {
        connectionBadgeLabel(language: storeLanguage)
    }

    public func connectionBadgeLabel(language: AppLanguage) -> String {
        if isWaitingForManualReconnect {
            return localized(.menuConnectionBadgeNeedsAttention, language: language)
        }

        switch connectionState {
        case .connected:
            return localized(.menuConnectionBadgeConnected, language: language)
        case .connecting:
            return localized(.menuConnectionBadgeConnecting, language: language)
        case .reconnecting:
            return localized(.menuConnectionBadgeRetrying, language: language)
        case .disconnected:
            return localized(.menuConnectionBadgeDisconnected, language: language)
        case .failed:
            return localized(.menuConnectionBadgeFailed, language: language)
        case .unconfigured:
            return localized(.menuConnectionBadgeUnconfigured, language: language)
        }
    }

    public var connectionStatusSummary: String {
        connectionStatusSummary(language: storeLanguage)
    }

    public func connectionStatusSummary(language: AppLanguage) -> String {
        if isWaitingForManualReconnect {
            return localized(.connectionSummaryAutoRetryStopped, language: language)
        }

        switch connectionState {
        case .connected:
            return lastUpdatedAt == nil
                ? localized(.connectionSummaryConnectedWaitingStatus, language: language)
                : localized(.connectionSummaryConnectedReceivingStatus, language: language)
        case .connecting:
            return localized(.connectionSummaryConnecting, language: language)
        case .reconnecting:
            return retryStatusLine(prefix: localized(.connectionSummaryFailed, language: language), language: language)
        case .disconnected:
            return retryStatusLine(prefix: localized(.connectionSummaryDisconnected, language: language), language: language)
        case .failed:
            return retryStatusLine(prefix: localized(.connectionSummaryFailed, language: language), language: language)
        case .unconfigured:
            return localized(.connectionSummaryUnconfigured, language: language)
        }
    }

    public var displayErrorMessage: String? {
        displayErrorMessage(language: storeLanguage)
    }

    public func displayErrorMessage(language: AppLanguage) -> String? {
        guard let lastErrorMessage, !lastErrorMessage.isEmpty else { return nil }
        return AppLocalization.localizedConnectionErrorMessage(lastErrorMessage, language: language)
    }

    public func cameraSnapshotErrorMessage(language: AppLanguage) -> String? {
        guard let cameraSnapshotErrorMessage, !cameraSnapshotErrorMessage.isEmpty else { return nil }
        return AppLocalization.localizedConnectionErrorMessage(cameraSnapshotErrorMessage, language: language)
    }

    private func emitWidgetSnapshot() {
        onWidgetSnapshotChange?(widgetSnapshot())
    }

    public func widgetSnapshot() -> WidgetSnapshot {
        let language = storeLanguage
        guard configuration != nil else {
            return .placeholder(language: language)
        }

        let statusLabel: String
        let tone: WidgetTone

        switch connectionState {
        case .unconfigured:
            return .placeholder(language: language)
        case .connecting:
            statusLabel = localized(.menuConnectionBadgeConnecting, language: language)
            tone = .muted
        case .reconnecting:
            statusLabel = localized(.menuConnectionBadgeRetrying, language: language)
            tone = .muted
        case .connected:
            switch printerStatus.state {
            case .printing:
                statusLabel = printerStatus.state.localizedLabel(language: language)
                tone = .accent
            case .paused:
                statusLabel = printerStatus.state.localizedLabel(language: language)
                tone = .muted
            case .complete:
                statusLabel = printerStatus.state.localizedLabel(language: language)
                tone = .neutral
            case .cancelled:
                statusLabel = printerStatus.state.localizedLabel(language: language)
                tone = .neutral
            case .error:
                statusLabel = printerStatus.state.localizedLabel(language: language)
                tone = .danger
            case .standby, .unknown:
                statusLabel = printerStatus.state.localizedLabel(language: language)
                tone = .muted
            }
        case .disconnected:
            statusLabel = localized(.menuConnectionBadgeDisconnected, language: language)
            tone = .danger
        case .failed:
            statusLabel = localized(.menuConnectionBadgeFailed, language: language)
            tone = .danger
        }

        let title: String = {
            if let filename = WidgetSnapshotFormatter.nonEmpty(printerStatus.filename) {
                return filename
            }
            switch connectionState {
            case .connected:
                return localized(.widgetTitleNoPrintTask, language: language)
            case .connecting:
                return localized(.widgetTitleConnecting, language: language)
            case .reconnecting:
                return localized(.widgetTitleReconnecting, language: language)
            case .disconnected:
                return localized(.widgetTitleDisconnected, language: language)
            case .failed:
                return localized(.widgetTitleFailed, language: language)
            case .unconfigured:
                return localized(.widgetTitleUnconfigured, language: language)
            }
        }()

        let summary: String = {
            if let message = WidgetSnapshotFormatter.nonEmpty(printerStatus.message) {
                return message
            }
            if let message = WidgetSnapshotFormatter.nonEmpty(displayErrorMessage) {
                return message
            }
            switch connectionState {
            case .connected:
                switch printerStatus.state {
                case .printing:
                    return localized(.widgetSummaryPrintingNormal, language: language)
                case .paused:
                    return localized(.widgetSummaryPaused, language: language)
                case .complete:
                    return localized(.widgetSummaryComplete, language: language)
                case .cancelled:
                    return localized(.widgetSummaryCancelled, language: language)
                case .error:
                    return localized(.widgetSummaryError, language: language)
                case .standby, .unknown:
                    return localized(.widgetSummaryStandby, language: language)
                }
            case .connecting:
                return localized(.widgetTitleConnecting, language: language)
            case .reconnecting:
                return connectionStatusSummary(language: language)
            case .disconnected:
                return localized(.widgetSummaryCheckConnection, language: language)
            case .failed:
                return localized(.widgetSummaryCheckConnection, language: language)
            case .unconfigured:
                return localized(.widgetSummaryUnconfigured, language: language)
            }
        }()

        return WidgetSnapshot(
            language: language,
            statusLabel: statusLabel,
            connectionLabel: connectionBadgeLabel(language: language),
            title: title,
            progress: printerStatus.normalizedProgress,
            progressLabel: WidgetSnapshotFormatter.percentLabel(for: printerStatus.progress),
            remainingTime: WidgetSnapshotFormatter.clockString(for: printerStatus.estimatedTimeRemaining),
            elapsedTime: WidgetSnapshotFormatter.clockString(for: printerStatus.printDuration),
            nozzle: WidgetSnapshotFormatter.temperatureString(for: printerStatus.extruder),
            bed: WidgetSnapshotFormatter.temperatureString(for: printerStatus.bed),
            layer: WidgetSnapshotFormatter.layerString(for: printerStatus.layer),
            speed: WidgetSnapshotFormatter.feedRateString(for: printerStatus.feedRateMultiplier),
            summary: summary,
            tone: tone
        )
    }

    public func start() {
        guard let configuration else {
            connectionState = .unconfigured
            log(.warning, "Connection start skipped: Moonraker is not configured")
            emitWidgetSnapshot()
            return
        }
        log(.info, "Connecting to Moonraker")
        connect(using: configuration, isReconnect: false)
    }

    public func reconnectNow() {
        reconnectNow(resetRetryBudget: true)
    }

    private func reconnectNow(resetRetryBudget: Bool) {
        guard let configuration else {
            connectionState = .unconfigured
            log(.warning, "Manual reconnect skipped: Moonraker is not configured")
            emitWidgetSnapshot()
            return
        }
        reconnectTask?.cancel()
        if resetRetryBudget {
            retryAttemptCount = 0
        }
        nextRetryAt = nil
        isWaitingForManualReconnect = false
        log(.info, resetRetryBudget ? "Manual reconnect requested" : "Running automatic reconnect")
        connect(using: configuration, isReconnect: true)
    }

    @discardableResult
    public func saveConfiguration(
        serverURLString: String,
        apiToken: String?,
        cameraSnapshotURL: String? = nil,
        appLanguage: AppLanguage? = nil
    ) async -> Bool {
        let configuration = MoonrakerConfiguration(
            serverURLString: serverURLString,
            apiToken: apiToken,
            cameraSnapshotURL: cameraSnapshotURL,
            appLanguage: appLanguage ?? self.configuration?.appLanguage ?? .system
        )
        do {
            _ = try configuration.validated()
            persistence.save(configuration)
            self.configuration = configuration
            lastErrorMessage = nil
            retryAttemptCount = 0
            nextRetryAt = nil
            isWaitingForManualReconnect = false
            log(.info, "Configuration saved: \(configuration.serverURLString)")
            log(.info, "Connecting to Moonraker")
            connect(using: configuration, isReconnect: false)
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            connectionState = .failed
            log(.error, "Failed to save configuration: \(AppLogStore.diagnosticDescription(for: error))")
            emitWidgetSnapshot()
            return false
        }
    }

    public func disconnect() {
        connectTask?.cancel()
        reconnectTask?.cancel()
        metadataFetchTask?.cancel()
        statusPublishTask?.cancel()
        connectTask = nil
        reconnectTask = nil
        metadataFetchTask = nil
        statusPublishTask = nil
        lastStatusPublishedAt = nil
        metadataFetchFilename = nil
        metadataFetchToken = nil
        metadataRescanFilename = nil
        currentPrintThumbnailRetryCount = 0
        isWaitingForManualCurrentPrintThumbnailRetry = false
        currentPrintThumbnailData = nil
        currentPrintThumbnailErrorMessage = nil
        isFetchingCurrentPrintThumbnail = false
        isDisconnectingIntentionally = true
        connectionState = configuration == nil ? .unconfigured : .disconnected
        nextRetryAt = nil
        isWaitingForManualReconnect = false
        log(.info, "Disconnected by user request")
        emitWidgetSnapshot()
        Task { await client.disconnect() }
    }

    @discardableResult
    public func fetchCameraSnapshot() async -> Bool {
        guard !isFetchingCameraSnapshot else {
            log(.debug, "Ignored duplicate camera snapshot request")
            return false
        }
        guard let configuration else {
            cameraSnapshotData = nil
            cameraSnapshotUpdatedAt = nil
            cameraSnapshotErrorMessage = MoonrakerConfigurationError.emptyURL.localizedDescription
            log(.warning, "Camera snapshot request skipped: Moonraker is not configured")
            return false
        }

        isFetchingCameraSnapshot = true
        cameraSnapshotErrorMessage = nil
        log(.info, "Requesting camera snapshot")

        defer {
            isFetchingCameraSnapshot = false
        }

        do {
            let validated = try configuration.validated()
            let snapshot = try await cameraClient.fetchSnapshot(configuration: validated)
            cameraSnapshotData = snapshot
            cameraSnapshotUpdatedAt = Date()
            log(.info, "Camera snapshot request succeeded: \(snapshot.count) bytes")
            return true
        } catch {
            cameraSnapshotData = nil
            cameraSnapshotUpdatedAt = nil
            cameraSnapshotErrorMessage = error.localizedDescription
            log(.error, "Camera snapshot request failed: \(AppLogStore.diagnosticDescription(for: error))")
            return false
        }
    }

    public func retryCurrentPrintThumbnail() {
        guard canManuallyRetryCurrentPrintThumbnail else { return }
        currentPrintThumbnailRetryCount = 0
        isWaitingForManualCurrentPrintThumbnailRetry = false
        metadataFetchTask?.cancel()
        metadataFetchTask = nil
        metadataFetchFilename = nil
        metadataFetchToken = nil
        metadataRescanFilename = nil
        currentPrintThumbnailErrorMessage = nil
        refreshPrintAssetsIfNeeded(for: printerStatus)
    }

    private func connect(using configuration: MoonrakerConfiguration, isReconnect: Bool) {
        connectTask?.cancel()
        reconnectTask?.cancel()
        metadataFetchTask?.cancel()
        statusPublishTask?.cancel()
        metadataFetchTask = nil
        statusPublishTask = nil
        lastStatusPublishedAt = nil
        metadataFetchFilename = nil
        metadataFetchToken = nil
        metadataRescanFilename = nil
        currentPrintThumbnailRetryCount = 0
        isWaitingForManualCurrentPrintThumbnailRetry = false
        currentPrintThumbnailData = nil
        currentPrintThumbnailErrorMessage = nil
        isFetchingCurrentPrintThumbnail = false
        isDisconnectingIntentionally = false
        connectionState = isReconnect ? .reconnecting : .connecting
        lastErrorMessage = nil
        nextRetryAt = nil
        if !isReconnect {
            isWaitingForManualReconnect = false
        }
        log(.debug, "\(isReconnect ? "Preparing reconnect" : "Preparing connection"): \(configuration.serverURLString)")
        emitWidgetSnapshot()

        connectTask = Task {
            do {
                let validated = try configuration.validated()
                await client.connect(configuration: validated) { [weak self] event in
                    Task { @MainActor [weak self] in
                        self?.handle(event: event)
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionState = .failed
                    self.lastErrorMessage = error.localizedDescription
                    self.log(.error, "Connection initialization failed: \(AppLogStore.diagnosticDescription(for: error))")
                    self.scheduleReconnectIfPossible()
                }
            }
        }
    }

    func handle(event: MoonrakerClientEvent) {
        switch event {
        case .connected:
            connectionState = .connected
            lastErrorMessage = nil
            retryAttemptCount = 0
            nextRetryAt = nil
            isWaitingForManualReconnect = false
            log(.info, "Moonraker connected")
            emitWidgetSnapshot()
        case .printerStatus(let status):
            let previousStatus = livePrinterStatus
            livePrinterStatus = status
            liveLastUpdatedAt = Date()
            logStatusUpdate(status)
            refreshPrintAssetsIfNeeded(for: livePrinterStatus)
            publishStatusUpdate(previousStatus: previousStatus)
        case .printerStatusDelta(let delta):
            let previousStatus = livePrinterStatus
            livePrinterStatus = livePrinterStatus.applying(delta: delta)
            liveLastUpdatedAt = Date()
            log(.debug, "Received printer status delta update")
            refreshPrintAssetsIfNeeded(for: livePrinterStatus)
            publishStatusUpdate(previousStatus: previousStatus)
        case .disconnected(let message):
            if shouldIgnoreTransientDisconnection(message) {
                log(.debug, "Ignored transient disconnect during connection setup")
                return
            }
            if isDisconnectingIntentionally {
                isDisconnectingIntentionally = false
                log(.debug, "Ignored client disconnect after user-requested disconnect")
                emitWidgetSnapshot()
                return
            }
            connectionState = configuration == nil ? .unconfigured : .disconnected
            if let message {
                lastErrorMessage = message
                log(.warning, "Connection disconnected: \(message)")
            } else {
                log(.warning, "Connection disconnected")
            }
            scheduleReconnectIfPossible()
        case .failed(let message):
            connectionState = .failed
            lastErrorMessage = message
            log(.error, "Connection failed: \(message)")
            scheduleReconnectIfPossible()
        }
    }

    private func scheduleReconnectIfPossible() {
        guard configuration != nil else { return }
        guard !isWaitingForManualReconnect else { return }

        let failureCount = retryAttemptCount + 1
        retryAttemptCount = failureCount

        guard failureCount < retryPolicy.maxAttempts else {
            reconnectTask?.cancel()
            reconnectTask = nil
            nextRetryAt = nil
            isWaitingForManualReconnect = true
            log(.error, "Automatic reconnect stopped after \(retryPolicy.maxAttempts) attempts")
            emitWidgetSnapshot()
            return
        }

        reconnectTask?.cancel()
        let delay = retryPolicy.delay(failureCount)
        nextRetryAt = Date().addingTimeInterval(delay.timeInterval)
        log(.warning, "Automatic reconnect scheduled in \(Int(delay.timeInterval.rounded())) seconds (\(failureCount)/\(retryPolicy.maxAttempts))")
        emitWidgetSnapshot()
        reconnectTask = Task { [weak self] in
            await self?.sleep(delay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.reconnectNow(resetRetryBudget: false)
            }
        }
    }

    private func shouldIgnoreTransientDisconnection(_ message: String?) -> Bool {
        (connectionState == .connecting || connectionState == .reconnecting) && message == "Disconnected"
    }

    private var storeLanguage: AppLanguage {
        (configuration?.appLanguage ?? .system).resolved(preferredLanguages: Locale.preferredLanguages)
    }

    private func localized(_ key: AppLocalization.Key, language: AppLanguage) -> String {
        AppLocalization.localizedString(key, language: language.resolved(preferredLanguages: Locale.preferredLanguages))
    }

    private func retryStatusLine(prefix: String, language: AppLanguage) -> String {
        if isWaitingForManualReconnect {
            return localized(.connectionSummaryAutoRetryStopped, language: language)
        }
        guard let nextRetryAt else {
            return prefix
        }
        let remaining = max(0, Int(nextRetryAt.timeIntervalSinceNow.rounded(.up)))
        let format = localized(.connectionSummaryRetryFormat, language: language)
        return String(
            format: format,
            locale: AppLocalization.locale(for: language),
            prefix,
            remaining,
            retryAttemptCount,
            retryPolicy.maxAttempts
        )
    }

    private func publishStatusUpdate(previousStatus: PrinterStatus) {
        if shouldPublishStatusImmediately(previousStatus: previousStatus, latestStatus: livePrinterStatus) {
            publishLatestStatus()
            return
        }

        guard let intervalSeconds = statusRefreshPolicy.intervalSeconds else {
            publishLatestStatus()
            return
        }

        guard let lastStatusPublishedAt else {
            publishLatestStatus()
            return
        }

        let interval = TimeInterval(intervalSeconds)
        let elapsed = Date().timeIntervalSince(lastStatusPublishedAt)
        guard elapsed < interval else {
            publishLatestStatus()
            return
        }

        scheduleStatusPublish(after: interval - elapsed)
    }

    private func shouldPublishStatusImmediately(previousStatus: PrinterStatus, latestStatus: PrinterStatus) -> Bool {
        guard statusRefreshPolicy != .realtime else {
            return true
        }
        guard lastStatusPublishedAt != nil else {
            return true
        }
        return previousStatus.state != latestStatus.state || previousStatus.filename != latestStatus.filename
    }

    private func scheduleStatusPublish(after delay: TimeInterval) {
        guard statusPublishTask == nil else {
            return
        }

        let milliseconds = max(1, Int((delay * 1000).rounded(.up)))
        statusPublishTask = Task { [weak self] in
            await self?.sleep(.milliseconds(milliseconds))
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                self?.publishLatestStatus()
            }
        }
    }

    private func publishLatestStatus() {
        statusPublishTask?.cancel()
        statusPublishTask = nil
        printerStatus = livePrinterStatus
        if let liveLastUpdatedAt {
            lastUpdatedAt = liveLastUpdatedAt
        }
        lastStatusPublishedAt = Date()
        emitWidgetSnapshot()
    }

    private func refreshPrintAssetsIfNeeded(for status: PrinterStatus) {
        let filename = status.filename?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let filename, !filename.isEmpty, let configuration else {
            metadataFetchTask?.cancel()
            metadataFetchTask = nil
            metadataFetchFilename = nil
            metadataRescanFilename = nil
            currentPrintThumbnailRetryCount = 0
            isWaitingForManualCurrentPrintThumbnailRetry = false
            livePrinterStatus.slicerEstimatedPrintTime = nil
            printerStatus.slicerEstimatedPrintTime = nil
            currentPrintThumbnailData = nil
            currentPrintThumbnailErrorMessage = nil
            isFetchingCurrentPrintThumbnail = false
            return
        }

        if metadataFetchFilename == filename, metadataFetchTask == nil, currentPrintThumbnailData != nil {
            return
        }

        if metadataFetchFilename == filename, metadataFetchTask == nil, isWaitingForManualCurrentPrintThumbnailRetry {
            return
        }

        if metadataFetchFilename == filename, metadataFetchTask != nil {
            return
        }

        if metadataFetchFilename == filename, metadataFetchTask == nil, currentPrintThumbnailData == nil {
            guard currentPrintThumbnailRetryCount < currentPrintThumbnailRetryLimit else {
                isWaitingForManualCurrentPrintThumbnailRetry = true
                log(
                    .debug,
                    "Current print thumbnail retry stopped after \(currentPrintThumbnailRetryLimit) attempts"
                )
                return
            }
        }

        metadataFetchTask?.cancel()
        metadataFetchFilename = filename
        metadataRescanFilename = nil
        currentPrintThumbnailRetryCount += 1
        isWaitingForManualCurrentPrintThumbnailRetry = false
        isFetchingCurrentPrintThumbnail = true
        currentPrintThumbnailErrorMessage = nil
        let fetchToken = UUID()
        metadataFetchToken = fetchToken

        metadataFetchTask = Task { [weak self] in
            guard let self else { return }

            defer {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard self.metadataFetchToken == fetchToken else { return }
                    self.metadataFetchTask = nil
                    self.metadataFetchToken = nil
                }
            }

            do {
                let validated = try configuration.validated()
                let metadata = try await client.fetchGCodeMetadata(configuration: validated, filename: filename)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    guard self.metadataFetchToken == fetchToken else { return }
                    guard self.metadataFetchFilename == filename else { return }
                    self.livePrinterStatus.slicerEstimatedPrintTime = metadata.estimatedTime
                    self.printerStatus.slicerEstimatedPrintTime = metadata.estimatedTime
                }
                await fetchThumbnailIfNeeded(
                    configuration: validated,
                    filename: filename,
                    metadata: metadata,
                    fetchToken: fetchToken
                )
            } catch {
                if Task.isCancelled {
                    return
                }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    guard self.metadataFetchToken == fetchToken else { return }
                    guard self.metadataFetchFilename == filename else { return }
                    self.livePrinterStatus.slicerEstimatedPrintTime = nil
                    self.printerStatus.slicerEstimatedPrintTime = nil
                    self.currentPrintThumbnailData = nil
                    self.currentPrintThumbnailErrorMessage = nil
                    self.isFetchingCurrentPrintThumbnail = false
                    self.log(.debug, "Failed to fetch slicer estimate: \(AppLogStore.diagnosticDescription(for: error))")
                }
            }
        }
    }

    private func fetchThumbnailIfNeeded(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        metadata: MoonrakerFileMetadata,
        fetchToken: UUID
        ) async {
        let thumbnail = await preferredThumbnailOrRescanIfNeeded(
            configuration: configuration,
            filename: filename,
            metadata: metadata,
            fetchToken: fetchToken
        )
        guard let thumbnail else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.metadataFetchToken == fetchToken else { return }
                self.isFetchingCurrentPrintThumbnail = false
                if self.currentPrintThumbnailRetryCount >= self.currentPrintThumbnailRetryLimit {
                    self.isWaitingForManualCurrentPrintThumbnailRetry = true
                }
            }
            return
        }

        await MainActor.run { [weak self] in
            guard let self else { return }
            guard self.metadataFetchToken == fetchToken else { return }
            self.isFetchingCurrentPrintThumbnail = true
            self.currentPrintThumbnailErrorMessage = nil
        }

        do {
            let data = try await client.fetchGCodeThumbnail(
                configuration: configuration,
                filename: filename,
                relativePath: thumbnail.relativePath
            )
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.metadataFetchToken == fetchToken else { return }
                self.currentPrintThumbnailData = data
                self.isFetchingCurrentPrintThumbnail = false
                self.currentPrintThumbnailRetryCount = 0
                self.isWaitingForManualCurrentPrintThumbnailRetry = false
                self.log(.info, "Current print thumbnail request succeeded: \(data.count) bytes")
            }
        } catch {
            if Task.isCancelled {
                return
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.metadataFetchToken == fetchToken else { return }
                self.currentPrintThumbnailData = nil
                self.currentPrintThumbnailErrorMessage = error.localizedDescription
                self.isFetchingCurrentPrintThumbnail = false
                if self.currentPrintThumbnailRetryCount >= self.currentPrintThumbnailRetryLimit {
                    self.isWaitingForManualCurrentPrintThumbnailRetry = true
                }
                self.log(.debug, "Failed to fetch current print thumbnail: \(AppLogStore.diagnosticDescription(for: error))")
            }
        }
    }

    private func preferredThumbnailOrRescanIfNeeded(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        metadata: MoonrakerFileMetadata,
        fetchToken: UUID
    ) async -> MoonrakerThumbnailInfo? {
        if let thumbnail = preferredThumbnail(for: metadata) {
            return thumbnail
        }

        guard metadataRescanFilename != filename else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.metadataFetchToken == fetchToken else { return }
                self.currentPrintThumbnailData = nil
                self.currentPrintThumbnailErrorMessage = nil
                self.isFetchingCurrentPrintThumbnail = false
                if self.currentPrintThumbnailRetryCount >= self.currentPrintThumbnailRetryLimit {
                    self.isWaitingForManualCurrentPrintThumbnailRetry = true
                }
            }
            return nil
        }

        metadataRescanFilename = filename
        do {
            try await client.rescanGCodeMetadata(configuration: configuration, filename: filename)
            let rescannedMetadata = try await client.fetchGCodeMetadata(
                configuration: configuration,
                filename: filename
            )
            return preferredThumbnail(for: rescannedMetadata)
        } catch {
            if Task.isCancelled {
                return nil
            }
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard self.metadataFetchToken == fetchToken else { return }
                self.currentPrintThumbnailData = nil
                self.currentPrintThumbnailErrorMessage = error.localizedDescription
                self.isFetchingCurrentPrintThumbnail = false
                if self.currentPrintThumbnailRetryCount >= self.currentPrintThumbnailRetryLimit {
                    self.isWaitingForManualCurrentPrintThumbnailRetry = true
                }
                self.log(.debug, "Failed to rescan current print thumbnail metadata: \(AppLogStore.diagnosticDescription(for: error))")
            }
            return nil
        }
    }

    private func preferredThumbnail(for metadata: MoonrakerFileMetadata) -> MoonrakerThumbnailInfo? {
        guard let thumbnails = metadata.thumbnails, !thumbnails.isEmpty else { return nil }
        return thumbnails.max { lhs, rhs in
            let lhsArea = (lhs.width ?? 0) * (lhs.height ?? 0)
            let rhsArea = (rhs.width ?? 0) * (rhs.height ?? 0)
            return lhsArea < rhsArea
        }
    }

    private func log(_ level: AppLogLevel, _ message: String) {
        logStore?.log(level, source: "PrinterStatusStore", message: message)
    }

    private func logStatusUpdate(_ status: PrinterStatus) {
        let progressText: String
        if let progress = status.progress {
            progressText = "\(Int((progress * 100).rounded()))%"
        } else {
            progressText = "--"
        }
        let filename = status.filename ?? "no active job"
        log(.info, "Received status update: state \(status.state.rawValue), progress \(progressText), job \(filename)")
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
