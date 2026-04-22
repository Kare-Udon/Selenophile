import SwiftUI
import SelenophileKit

struct SettingsView: View {
    let store: PrinterStatusStore
    let onClose: () -> Void
    let onCancel: () -> Void
    let onLanguageSelectionPreview: (AppLanguage) -> Void
    let launchAtLoginControl: LaunchAtLoginControl?
    let appLanguageStore: AppLanguageStore

    @State private var serverURLString: String
    @State private var apiToken: String
    @State private var cameraSnapshotURL: String
    @State private var selectedAppLanguage: AppLanguage
    @State private var launchAtLoginEnabled: Bool
    @State private var isUpdatingLaunchAtLogin = false
    @State private var isSaving = false
    @State private var selectedSection: SettingsSection = .connection
    @State private var connectionTestFeedback: ConnectionTestFeedback?

    init(
        store: PrinterStatusStore,
        onClose: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onLanguageSelectionPreview: @escaping (AppLanguage) -> Void = { _ in },
        launchAtLoginControl: LaunchAtLoginControl? = nil,
        appLanguageStore: AppLanguageStore
    ) {
        self.store = store
        self.onClose = onClose
        self.onCancel = onCancel
        self.onLanguageSelectionPreview = onLanguageSelectionPreview
        self.launchAtLoginControl = launchAtLoginControl
        self.appLanguageStore = appLanguageStore
        _serverURLString = State(initialValue: store.configuration?.serverURLString ?? "http://127.0.0.1:7125")
        _apiToken = State(initialValue: store.configuration?.apiToken ?? "")
        _cameraSnapshotURL = State(initialValue: store.configuration?.cameraSnapshotURL ?? "")
        _selectedAppLanguage = State(initialValue: store.configuration?.appLanguage ?? .system)
        _launchAtLoginEnabled = State(initialValue: launchAtLoginControl?.isEnabled() ?? false)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            VStack(spacing: 0) {
                contentHeader
                Divider()
                    .overlay(SelenophileTheme.Colors.divider)
                settingsContent
                Divider()
                    .overlay(SelenophileTheme.Colors.divider)
                footerActions
            }
        }
        .frame(width: 840, height: 580)
        .background {
            SelenophileWindowBackground()
        }
        .onAppear {
            refreshLaunchAtLoginState()
            onLanguageSelectionPreview(selectedAppLanguage)
        }
    }

    @MainActor
    private func submit(closeOnSuccess: Bool) async {
        isSaving = true
        connectionTestFeedback = nil
        let token = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = await store.saveConfiguration(
            serverURLString: serverURLString,
            apiToken: token.isEmpty ? nil : token,
            cameraSnapshotURL: cameraSnapshotURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : cameraSnapshotURL.trimmingCharacters(in: .whitespacesAndNewlines),
            appLanguage: selectedAppLanguage
        )
        isSaving = false
        if success && closeOnSuccess {
            onClose()
        }
    }

    @MainActor
    private func runConnectionTest() async {
        isSaving = true
        connectionTestFeedback = nil

        defer {
            isSaving = false
        }

        let trimmedToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSnapshotURL = cameraSnapshotURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let configuration = MoonrakerConfiguration(
            serverURLString: serverURLString,
            apiToken: trimmedToken.isEmpty ? nil : trimmedToken,
            cameraSnapshotURL: trimmedSnapshotURL.isEmpty
                ? nil
                : trimmedSnapshotURL,
            appLanguage: selectedAppLanguage
        )

        do {
            let validated = try configuration.validated()
            let result = await MoonrakerConnectionProbe.test(
                configuration: validated,
                timeoutMessage: l10n(.settingsConnectionTestTimeout)
            )

            switch result {
            case .success:
                connectionTestFeedback = .init(
                    message: l10n(.settingsConnectionTestSuccess),
                    isError: false
                )
            case .failure(let message):
                connectionTestFeedback = .init(message: message, isError: true)
            }
        } catch {
            connectionTestFeedback = .init(message: error.localizedDescription, isError: true)
        }
    }

    private var uiLanguage: AppLanguage {
        selectedAppLanguage.resolved(preferredLanguages: Locale.preferredLanguages)
    }

    private func l10n(_ key: AppLocalization.Key) -> String {
        AppLocalization.localizedString(key, language: uiLanguage)
    }

    @MainActor
    private func refreshLaunchAtLoginState() {
        guard let launchAtLoginControl else {
            launchAtLoginEnabled = false
            return
        }
        launchAtLoginEnabled = launchAtLoginControl.isEnabled()
    }

    @MainActor
    private func updateLaunchAtLoginEnabled(_ enabled: Bool) async {
        guard let launchAtLoginControl, launchAtLoginControl.isAvailable else { return }
        guard !isUpdatingLaunchAtLogin else { return }

        isUpdatingLaunchAtLogin = true
        launchAtLoginEnabled = enabled
        await launchAtLoginControl.setIsEnabled(enabled)
        refreshLaunchAtLoginState()
        isUpdatingLaunchAtLogin = false
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selenophile")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)

                Text("FOR MOONRAKER")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .tracking(1.8)
            }

            VStack(spacing: 8) {
                ForEach(SettingsSection.allCases, id: \.self) { section in
                    sidebarButton(for: section)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 14) {
                Text(l10n(.settingsAboutBody))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach([
                    l10n(.settingsFeatureStatus),
                    l10n(.settingsFeatureLogs),
                    l10n(.settingsFeatureSecurity)
                ], id: \.self) { item in
                    Label(item, systemImage: "checkmark.shield")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                }
            }
            .padding(16)
            .selenophileCard(
                cornerRadius: SelenophileTheme.Metrics.mediumCorner,
                fill: SelenophileTheme.Colors.surfaceMuted
            )
        }
        .padding(22)
        .frame(width: 228, alignment: .topLeading)
        .background(
            SelenophileTheme.Colors.surfaceMuted.opacity(0.82)
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(SelenophileTheme.Colors.divider)
                .frame(width: 1)
        }
    }

    private func sidebarButton(for section: SettingsSection) -> some View {
        Button {
            selectedSection = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 18, height: 18)

                Text(section.title(in: uiLanguage))
                    .font(.system(size: 14, weight: .medium, design: .rounded))

                Spacer(minLength: 0)
            }
            .foregroundStyle(
                selectedSection == section
                    ? SelenophileTheme.Colors.primaryText
                    : SelenophileTheme.Colors.secondaryText
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        selectedSection == section
                            ? SelenophileTheme.Colors.surfaceRaised
                            : Color.clear
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var contentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SelenophileSectionLabel(text: selectedSection.title(in: uiLanguage))

                Text(headerTitle)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)
            }

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }

    private var headerTitle: String {
        switch selectedSection {
        case .connection:
            return l10n(.settingsHeroTitle)
        case .general:
            return l10n(.settingsGeneralSection)
        case .appearance:
            return l10n(.settingsAppearanceSection)
        case .advanced:
            return l10n(.settingsAdvancedSection)
        case .about:
            return l10n(.settingsAboutSection)
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                switch selectedSection {
                case .connection:
                    connectionSection
                case .general:
                    generalSection
                case .appearance:
                    placeholderSection(title: l10n(.settingsAppearanceSection))
                case .advanced:
                    placeholderSection(title: l10n(.settingsAdvancedSection))
                case .about:
                    aboutSection
                }

                if let connectionTestFeedback {
                    feedbackBanner(connectionTestFeedback)
                }

                if let error = store.displayErrorMessage, !error.isEmpty {
                    errorBanner(error)
                }
            }
            .padding(24)
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard {
                formField(title: l10n(.settingsMoonrakerURLLabel)) {
                    TextField(l10n(.settingsMoonrakerURLPlaceholder), text: $serverURLString)
                        .textFieldStyle(SelenophileTextFieldStyle())
                }

                formField(title: l10n(.settingsAPITokenLabel)) {
                    SecureField(l10n(.settingsAPITokenPlaceholder), text: $apiToken)
                        .textFieldStyle(SelenophileTextFieldStyle())
                }

                formField(title: l10n(.settingsCameraSnapshotURLLabel)) {
                    TextField(l10n(.settingsCameraSnapshotURLPlaceholder), text: $cameraSnapshotURL)
                        .textFieldStyle(SelenophileTextFieldStyle())
                }

                Text(l10n(.settingsConnectionHint))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard {
                formField(title: l10n(.settingsLanguageLabel)) {
                    languagePicker
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(l10n(.settingsLaunchAtLoginLabel))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.primaryText)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(l10n(.settingsLaunchAtLoginDescription))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            if !(launchAtLoginControl?.isAvailable ?? false) {
                                Text(l10n(.settingsLaunchAtLoginUnavailable))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(SelenophileTheme.Colors.tertiaryText)
                            }
                        }

                        Spacer(minLength: 12)

                        Toggle("", isOn: Binding(
                            get: { launchAtLoginEnabled },
                            set: { newValue in
                                Task { await updateLaunchAtLoginEnabled(newValue) }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: SelenophileTheme.Colors.accent))
                        .disabled(!(launchAtLoginControl?.isAvailable ?? false) || isUpdatingLaunchAtLogin)
                    }
                }
            }
        }
    }

    private func placeholderSection(title: String) -> some View {
        settingsCard {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)

            Text(l10n(.settingsNoAdditionalOptions))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
        }
    }

    private var aboutSection: some View {
        settingsCard {
            Text("Selenophile")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)

            Text(l10n(.settingsAboutBody))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .selenophileCard()
    }

    private func formField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)

            content()
        }
    }

    private func errorBanner(_ error: String) -> some View {
        feedbackBanner(.init(message: error, isError: true))
    }

    private func feedbackBanner(_ feedback: ConnectionTestFeedback) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: feedback.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(feedback.isError ? SelenophileTheme.Colors.danger : SelenophileTheme.Colors.success)

            Text(feedback.message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .selenophileCard(
            cornerRadius: SelenophileTheme.Metrics.mediumCorner,
            fill: feedback.isError
                ? SelenophileTheme.Colors.danger.opacity(0.15)
                : SelenophileTheme.Colors.success.opacity(0.15),
            strokeOpacity: 0.45
        )
    }

    private var footerActions: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)

            Button(isSaving ? l10n(.settingsSaving) : l10n(.settingsTestConnection)) {
                Task { await runConnectionTest() }
            }
            .buttonStyle(SelenophileButtonStyle(kind: .secondary))
            .disabled(isSaving)

            Button(isSaving ? l10n(.settingsSaving) : l10n(.settingsSave)) {
                Task { await submit(closeOnSuccess: true) }
            }
            .buttonStyle(SelenophileButtonStyle(kind: .primary))
            .keyboardShortcut(.defaultAction)
            .disabled(isSaving)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var languagePicker: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SelenophileTheme.Colors.inputFill)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SelenophileTheme.Colors.inputBorder, lineWidth: 1)

            AppLanguagePopUpButton(
                selection: $selectedAppLanguage,
                uiLanguage: uiLanguage,
                onSelectionChanged: { language in
                    onLanguageSelectionPreview(language)
                }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                .padding(.trailing, 14)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }
}

private struct ConnectionTestFeedback: Equatable {
    let message: String
    let isError: Bool
}

private enum ConnectionProbeOutcome: Equatable {
    case success
    case failure(String)
}

extension SettingsView {
    struct LaunchAtLoginControl {
        let isAvailable: Bool
        let isEnabled: () -> Bool
        let setIsEnabled: (Bool) async -> Void

        init(
            isAvailable: Bool = true,
            isEnabled: @escaping () -> Bool,
            setIsEnabled: @escaping (Bool) async -> Void
        ) {
            self.isAvailable = isAvailable
            self.isEnabled = isEnabled
            self.setIsEnabled = setIsEnabled
        }
    }
}

private enum SettingsSection: CaseIterable {
    case connection
    case general
    case appearance
    case advanced
    case about

    var symbolName: String {
        switch self {
        case .connection:
            return "link"
        case .general:
            return "gearshape"
        case .appearance:
            return "paintpalette"
        case .advanced:
            return "wrench.and.screwdriver"
        case .about:
            return "info.circle"
        }
    }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .connection:
            return AppLocalization.localizedString(.settingsConnectionSection, language: language)
        case .general:
            return AppLocalization.localizedString(.settingsGeneralSection, language: language)
        case .appearance:
            return AppLocalization.localizedString(.settingsAppearanceSection, language: language)
        case .advanced:
            return AppLocalization.localizedString(.settingsAdvancedSection, language: language)
        case .about:
            return AppLocalization.localizedString(.settingsAboutSection, language: language)
        }
    }
}

private struct AppLanguagePopUpButton: NSViewRepresentable {
    @Binding var selection: AppLanguage
    let uiLanguage: AppLanguage
    let onSelectionChanged: (AppLanguage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, onSelectionChanged: onSelectionChanged)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionDidChange(_:))
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.bezelStyle = .shadowlessSquare
        button.controlSize = .regular
        button.isBordered = false
        button.contentTintColor = NSColor.white
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 28)
        ])
        update(button)
        return button
    }

    func updateNSView(_ nsView: NSPopUpButton, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.onSelectionChanged = onSelectionChanged
        update(nsView)
    }

    private func update(_ button: NSPopUpButton) {
        let currentTitles = button.itemTitles
        let desiredTitles = AppLanguage.supportedSelections.map { $0.displayName(in: uiLanguage) }

        if currentTitles != desiredTitles {
            button.removeAllItems()
            button.addItems(withTitles: desiredTitles)
        }

        if let index = AppLanguage.supportedSelections.firstIndex(of: selection),
           button.indexOfSelectedItem != index {
            button.selectItem(at: index)
        }
    }

    final class Coordinator: NSObject {
        var selection: Binding<AppLanguage>
        var onSelectionChanged: (AppLanguage) -> Void

        init(
            selection: Binding<AppLanguage>,
            onSelectionChanged: @escaping (AppLanguage) -> Void
        ) {
            self.selection = selection
            self.onSelectionChanged = onSelectionChanged
        }

        @MainActor
        @objc
        func selectionDidChange(_ sender: NSPopUpButton) {
            let index = sender.indexOfSelectedItem
            guard AppLanguage.supportedSelections.indices.contains(index) else { return }
            let language = AppLanguage.supportedSelections[index]
            selection.wrappedValue = language
            onSelectionChanged(language)
        }
    }
}

private final class MoonrakerConnectionProbeRelay: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<ConnectionProbeOutcome, Never>?
    private var resolvedResult: ConnectionProbeOutcome?

    func install(_ continuation: CheckedContinuation<ConnectionProbeOutcome, Never>) {
        let resultToResume = lock.withLock { () -> ConnectionProbeOutcome? in
            if let resolvedResult {
                return resolvedResult
            }
            self.continuation = continuation
            return nil
        }

        if let resultToResume {
            continuation.resume(returning: resultToResume)
        }
    }

    func handle(_ event: MoonrakerClientEvent) {
        switch event {
        case .connected:
            resolve(.success)
        case .failed(let message):
            resolve(.failure(message))
        case .disconnected(let reason):
            if let reason, !reason.isEmpty {
                resolve(.failure(reason))
            }
        case .printerStatus, .printerStatusDelta:
            break
        }
    }

    func timeout(message: String) {
        resolve(.failure(message))
    }

    private func resolve(_ result: ConnectionProbeOutcome) {
        let continuationToResume = lock.withLock { () -> CheckedContinuation<ConnectionProbeOutcome, Never>? in
            guard resolvedResult == nil else { return nil }
            resolvedResult = result
            let continuation = continuation
            self.continuation = nil
            return continuation
        }

        continuationToResume?.resume(returning: result)
    }
}

private enum MoonrakerConnectionProbe {
    static func test(
        configuration: MoonrakerValidatedConfiguration,
        timeoutMessage: String,
        timeout: Duration = .seconds(4)
    ) async -> ConnectionProbeOutcome {
        let client = MoonrakerClient()
        let relay = MoonrakerConnectionProbeRelay()

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<ConnectionProbeOutcome, Never>) in
            relay.install(continuation)

            Task {
                await client.connect(configuration: configuration) { event in
                    relay.handle(event)
                }
            }

            Task {
                try? await Task.sleep(for: timeout)
                relay.timeout(message: timeoutMessage)
            }
        }

        await client.disconnect()
        return result
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
