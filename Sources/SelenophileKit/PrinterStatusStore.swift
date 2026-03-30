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
        switch self {
        case .unconfigured:
            return "未配置"
        case .connecting:
            return "连接中"
        case .connected:
            return "已连接"
        case .reconnecting:
            return "重连中"
        case .disconnected:
            return "已断开"
        case .failed:
            return "连接失败"
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
    private let key = "moonraker.configuration"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> MoonrakerConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(MoonrakerConfiguration.self, from: data)
    }

    public func save(_ configuration: MoonrakerConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
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
    public var lastErrorMessage: String?
    public var lastUpdatedAt: Date?
    public var onWidgetSnapshotChange: ((WidgetSnapshot) -> Void)?
    public var onConfigurationChange: ((MoonrakerConfiguration?) -> Void)?
    public private(set) var cameraSnapshotData: Data?
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

    public init(
        client: MoonrakerClientProtocol = MoonrakerClient(),
        cameraClient: MoonrakerCameraClientProtocol = MoonrakerCameraClient(),
        persistence: MoonrakerConfigurationPersisting = UserDefaultsMoonrakerConfigurationStore(),
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
        if isWaitingForManualReconnect {
            return "需要处理"
        }

        switch connectionState {
        case .connected:
            return "已连接"
        case .connecting:
            return "连接中"
        case .reconnecting:
            return "重试中"
        case .disconnected:
            return "已断开"
        case .failed:
            return "连接失败"
        case .unconfigured:
            return "待配置"
        }
    }

    public var connectionStatusSummary: String {
        if isWaitingForManualReconnect {
            return "自动重试已停止，请手动重连"
        }

        switch connectionState {
        case .connected:
            return lastUpdatedAt == nil ? "已建立连接，等待首个状态更新" : "连接正常，正在接收 Moonraker 状态"
        case .connecting:
            return "正在连接 Moonraker"
        case .reconnecting:
            return retryStatusLine(prefix: "连接失败")
        case .disconnected:
            return retryStatusLine(prefix: "连接已断开")
        case .failed:
            return retryStatusLine(prefix: "连接失败")
        case .unconfigured:
            return "请先填写 Moonraker 地址"
        }
    }

    public var displayErrorMessage: String? {
        guard let lastErrorMessage, !lastErrorMessage.isEmpty else { return nil }
        return translatedErrorMessage(lastErrorMessage)
    }

    private func emitWidgetSnapshot() {
        onWidgetSnapshotChange?(widgetSnapshot())
    }

    public func widgetSnapshot() -> WidgetSnapshot {
        guard configuration != nil else {
            return .placeholder
        }

        let statusLabel: String
        let tone: WidgetTone

        switch connectionState {
        case .unconfigured:
            return .placeholder
        case .connecting:
            statusLabel = "连接中"
            tone = .muted
        case .reconnecting:
            statusLabel = "重连中"
            tone = .muted
        case .connected:
            switch printerStatus.state {
            case .printing:
                statusLabel = "打印中"
                tone = .accent
            case .paused:
                statusLabel = "已暂停"
                tone = .muted
            case .complete:
                statusLabel = "已完成"
                tone = .neutral
            case .cancelled:
                statusLabel = "已取消"
                tone = .neutral
            case .error:
                statusLabel = "错误"
                tone = .danger
            case .standby, .unknown:
                statusLabel = "待机"
                tone = .muted
            }
        case .disconnected:
            statusLabel = "已断开"
            tone = .danger
        case .failed:
            statusLabel = "连接失败"
            tone = .danger
        }

        let title: String = {
            if let filename = WidgetSnapshotFormatter.nonEmpty(printerStatus.filename) {
                return filename
            }
            switch connectionState {
            case .connected:
                return "当前无打印任务"
            case .connecting:
                return "正在连接 Moonraker"
            case .reconnecting:
                return "正在重连 Moonraker"
            case .disconnected:
                return "Moonraker 已断开"
            case .failed:
                return "Moonraker 连接异常"
            case .unconfigured:
                return "请先设置 Moonraker 地址"
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
                    return "正在稳定打印，状态正常"
                case .paused:
                    return "打印已暂停"
                case .complete:
                    return "打印已完成"
                case .cancelled:
                    return "打印已取消"
                case .error:
                    return "打印状态异常"
                case .standby, .unknown:
                    return "打印机已连接，当前没有活动任务"
                }
            case .connecting:
                return "正在连接 Moonraker"
            case .reconnecting:
                return connectionStatusSummary
            case .disconnected:
                return "请检查 Moonraker 地址或网络连接"
            case .failed:
                return "请检查 Moonraker 地址或网络连接"
            case .unconfigured:
                return "还没有可用的打印状态数据"
            }
        }()

        return WidgetSnapshot(
            statusLabel: statusLabel,
            connectionLabel: connectionBadgeLabel,
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
            log(.warning, "启动连接失败：尚未配置 Moonraker")
            emitWidgetSnapshot()
            return
        }
        log(.info, "开始连接 Moonraker")
        connect(using: configuration, isReconnect: false)
    }

    public func reconnectNow() {
        reconnectNow(resetRetryBudget: true)
    }

    private func reconnectNow(resetRetryBudget: Bool) {
        guard let configuration else {
            connectionState = .unconfigured
            log(.warning, "手动重连失败：尚未配置 Moonraker")
            emitWidgetSnapshot()
            return
        }
        reconnectTask?.cancel()
        if resetRetryBudget {
            retryAttemptCount = 0
        }
        nextRetryAt = nil
        isWaitingForManualReconnect = false
        log(.info, resetRetryBudget ? "触发手动重连" : "开始执行自动重连")
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
            log(.info, "配置已保存：\(configuration.serverURLString)")
            log(.info, "开始连接 Moonraker")
            connect(using: configuration, isReconnect: false)
            return true
        } catch {
            lastErrorMessage = error.localizedDescription
            connectionState = .failed
            log(.error, "配置保存失败：\(error.localizedDescription)")
            emitWidgetSnapshot()
            return false
        }
    }

    public func disconnect() {
        connectTask?.cancel()
        reconnectTask?.cancel()
        metadataFetchTask?.cancel()
        connectTask = nil
        reconnectTask = nil
        metadataFetchTask = nil
        metadataFetchFilename = nil
        metadataFetchToken = nil
        metadataRescanFilename = nil
        currentPrintThumbnailRetryCount = 0
        isWaitingForManualCurrentPrintThumbnailRetry = false
        currentPrintThumbnailData = nil
        currentPrintThumbnailErrorMessage = nil
        isFetchingCurrentPrintThumbnail = false
        connectionState = configuration == nil ? .unconfigured : .disconnected
        nextRetryAt = nil
        isWaitingForManualReconnect = false
        log(.info, "已主动断开连接")
        emitWidgetSnapshot()
        Task { await client.disconnect() }
    }

    @discardableResult
    public func fetchCameraSnapshot() async -> Bool {
        guard !isFetchingCameraSnapshot else {
            log(.debug, "忽略重复的相机快照请求")
            return false
        }
        guard let configuration else {
            cameraSnapshotData = nil
            cameraSnapshotErrorMessage = "请先配置 Moonraker 地址。"
            log(.warning, "相机快照请求失败：尚未配置 Moonraker")
            return false
        }

        isFetchingCameraSnapshot = true
        cameraSnapshotErrorMessage = nil
        log(.info, "开始请求相机快照")

        defer {
            isFetchingCameraSnapshot = false
        }

        do {
            let validated = try configuration.validated()
            let snapshot = try await cameraClient.fetchSnapshot(configuration: validated)
            cameraSnapshotData = snapshot
            log(.info, "相机快照请求成功，大小 \(snapshot.count) 字节")
            return true
        } catch {
            cameraSnapshotData = nil
            cameraSnapshotErrorMessage = error.localizedDescription
            log(.error, "相机快照请求失败：\(error.localizedDescription)")
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
        metadataFetchTask = nil
        metadataFetchFilename = nil
        metadataFetchToken = nil
        metadataRescanFilename = nil
        currentPrintThumbnailRetryCount = 0
        isWaitingForManualCurrentPrintThumbnailRetry = false
        currentPrintThumbnailData = nil
        currentPrintThumbnailErrorMessage = nil
        isFetchingCurrentPrintThumbnail = false
        connectionState = isReconnect ? .reconnecting : .connecting
        lastErrorMessage = nil
        nextRetryAt = nil
        if !isReconnect {
            isWaitingForManualReconnect = false
        }
        log(.debug, "\(isReconnect ? "准备重连" : "准备连接")：\(configuration.serverURLString)")
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
                    self.log(.error, "连接初始化失败：\(error.localizedDescription)")
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
            log(.info, "Moonraker 已连接")
            emitWidgetSnapshot()
        case .printerStatus(let status):
            printerStatus = status
            lastUpdatedAt = Date()
            logStatusUpdate(status)
            refreshPrintAssetsIfNeeded(for: status)
            emitWidgetSnapshot()
        case .printerStatusDelta(let delta):
            printerStatus = printerStatus.applying(delta: delta)
            lastUpdatedAt = Date()
            log(.debug, "收到打印状态增量更新")
            refreshPrintAssetsIfNeeded(for: printerStatus)
            emitWidgetSnapshot()
        case .disconnected(let message):
            if shouldIgnoreTransientDisconnection(message) {
                log(.debug, "忽略连接阶段的瞬时断开事件")
                return
            }
            connectionState = configuration == nil ? .unconfigured : .disconnected
            if let message {
                lastErrorMessage = message
                log(.warning, "连接已断开：\(message)")
            } else {
                log(.warning, "连接已断开")
            }
            scheduleReconnectIfPossible()
        case .failed(let message):
            connectionState = .failed
            lastErrorMessage = message
            log(.error, "连接失败：\(message)")
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
            log(.error, "自动重试已停止，达到最大次数 \(retryPolicy.maxAttempts)")
            emitWidgetSnapshot()
            return
        }

        reconnectTask?.cancel()
        let delay = retryPolicy.delay(failureCount)
        nextRetryAt = Date().addingTimeInterval(delay.timeInterval)
        log(.warning, "将在 \(Int(delay.timeInterval.rounded())) 秒后自动重试（\(failureCount)/\(retryPolicy.maxAttempts)）")
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
        (connectionState == .connecting || connectionState == .reconnecting) && message == "已断开连接"
    }

    private func retryStatusLine(prefix: String) -> String {
        if isWaitingForManualReconnect {
            return "自动重试已停止，请手动重连"
        }
        guard let nextRetryAt else {
            return prefix
        }
        let remaining = max(0, Int(nextRetryAt.timeIntervalSinceNow.rounded(.up)))
        return "\(prefix)，\(remaining) 秒后重试（\(retryAttemptCount)/\(retryPolicy.maxAttempts)）"
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
                    "打印缩略图自动重试已停止，达到最大次数 \(currentPrintThumbnailRetryLimit)"
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
                    self.printerStatus.slicerEstimatedPrintTime = nil
                    self.currentPrintThumbnailData = nil
                    self.currentPrintThumbnailErrorMessage = nil
                    self.isFetchingCurrentPrintThumbnail = false
                    self.log(.debug, "获取 slicer 估时失败：\(error.localizedDescription)")
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
                self.log(.info, "打印缩略图请求成功，大小 \(data.count) 字节")
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
                self.log(.debug, "获取打印缩略图失败：\(error.localizedDescription)")
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
                self.log(.debug, "重扫打印缩略图失败：\(error.localizedDescription)")
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

    private func translatedErrorMessage(_ message: String) -> String {
        let normalized = message.lowercased()

        if normalized.contains("failed to decode jwt") || normalized.contains("jwt") {
            return "Moonraker 鉴权失败，请检查 JWT 或 API token。"
        }
        if normalized.contains("couldn't be read")
            || normalized.contains("couldn’t be read")
            || normalized.contains("could not be read")
            || normalized.contains("isn’t in the correct format")
            || normalized.contains("isn't in the correct format")
            || normalized.contains("is in the wrong format")
        {
            return "Moonraker 返回的数据格式与当前解析规则不一致。"
        }
        if normalized.contains("timed out") {
            return "连接 Moonraker 超时。"
        }
        if normalized.contains("could not connect")
            || normalized.contains("cannot connect")
            || normalized.contains("network is unreachable")
            || normalized.contains("connection refused")
        {
            return "无法连接到 Moonraker，请检查地址、端口或网络。"
        }
        if normalized.contains("cancelled") || normalized.contains("canceled") {
            return "连接已取消。"
        }
        return message
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
        let filename = status.filename ?? "无任务"
        log(.info, "收到状态更新：\(status.state.localizedLabel)，进度 \(progressText)，任务 \(filename)")
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        let components = components
        return TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
    }
}
