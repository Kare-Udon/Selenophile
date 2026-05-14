import SwiftUI
import SelenophileKit

struct SettingsView: View {
    let store: PrinterStatusStore
    let onClose: () -> Void
    let onCancel: () -> Void
    let onLanguageSelectionPreview: (AppLanguage) -> Void
    let launchAtLoginControl: LaunchAtLoginControl?
    let updateChecker: (any AppUpdateChecking)?
    let appLanguageStore: AppLanguageStore
    let appAppearanceStore: AppAppearanceStore

    @State private var serverURLString: String
    @State private var apiToken: String
    @State private var cameraSnapshotURL: String
    @State private var selectedAppLanguage: AppLanguage
    @State private var selectedAppearanceMode: AppAppearanceMode
    @State private var selectedThemePalette: AppThemePalette
    @State private var selectedStatusRefreshPolicy: PrinterStatusRefreshPolicy
    @State private var launchAtLoginEnabled: Bool
    @State private var isUpdatingLaunchAtLogin = false
    @State private var isSaving = false
    @State private var isTestingConnection = false
    @State private var selectedSection: SettingsSection = .connection
    @State private var connectionTestFeedback: ConnectionTestFeedback?

    init(
        store: PrinterStatusStore,
        onClose: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onLanguageSelectionPreview: @escaping (AppLanguage) -> Void = { _ in },
        launchAtLoginControl: LaunchAtLoginControl? = nil,
        updateChecker: (any AppUpdateChecking)? = nil,
        appLanguageStore: AppLanguageStore,
        appAppearanceStore: AppAppearanceStore
    ) {
        self.store = store
        self.onClose = onClose
        self.onCancel = onCancel
        self.onLanguageSelectionPreview = onLanguageSelectionPreview
        self.launchAtLoginControl = launchAtLoginControl
        self.updateChecker = updateChecker
        self.appLanguageStore = appLanguageStore
        self.appAppearanceStore = appAppearanceStore
        _serverURLString = State(initialValue: store.configuration?.serverURLString ?? "http://127.0.0.1:7125")
        _apiToken = State(initialValue: store.configuration?.apiToken ?? "")
        _cameraSnapshotURL = State(initialValue: store.configuration?.cameraSnapshotURL ?? "")
        _selectedAppLanguage = State(initialValue: store.configuration?.appLanguage ?? .system)
        _selectedAppearanceMode = State(initialValue: appAppearanceStore.selectedMode)
        _selectedThemePalette = State(initialValue: appAppearanceStore.selectedPalette)
        _selectedStatusRefreshPolicy = State(initialValue: store.statusRefreshPolicy)
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
            selectedAppearanceMode = appAppearanceStore.selectedMode
            selectedThemePalette = appAppearanceStore.selectedPalette
            selectedStatusRefreshPolicy = store.statusRefreshPolicy
        }
        .onChange(of: appLanguageStore.selectedLanguage) { _, language in
            selectedAppLanguage = language
        }
    }

    @MainActor
    private func submit(closeOnSuccess: Bool) async {
        isSaving = true
        connectionTestFeedback = nil
        let success = await SettingsViewSubmission.save(
            store: store,
            appAppearanceStore: appAppearanceStore,
            serverURLString: serverURLString,
            apiToken: apiToken,
            cameraSnapshotURL: cameraSnapshotURL,
            appLanguage: selectedAppLanguage,
            appearanceMode: selectedAppearanceMode,
            themePalette: selectedThemePalette,
            statusRefreshPolicy: selectedStatusRefreshPolicy
        )
        isSaving = false
        if success && closeOnSuccess {
            onClose()
        }
    }

    @MainActor
    private func runConnectionTest() async {
        isTestingConnection = true
        connectionTestFeedback = nil

        defer {
            isTestingConnection = false
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
        languageForLocalizedText(preferredLanguages: Locale.preferredLanguages)
    }

    func languageForLocalizedText(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        appLanguageStore.effectiveLanguage(preferredLanguages: preferredLanguages)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                    appearanceSection
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

                HStack(alignment: .center, spacing: 12) {
                    Text(l10n(.settingsConnectionHint))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    Button(isTestingConnection ? l10n(.settingsTestingConnection) : l10n(.settingsTestConnection)) {
                        Task { await runConnectionTest() }
                    }
                    .buttonStyle(SelenophileButtonStyle(kind: .secondary))
                    .disabled(isSaving || isTestingConnection)
                }
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard {
                formField(title: l10n(.settingsLanguageLabel)) {
                    languagePicker
                }

                formField(title: l10n(.settingsStatusRefreshRateLabel)) {
                    statusRefreshSlider
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
                        .accessibilityLabel(l10n(.settingsLaunchAtLoginLabel))
                        .accessibilityHint(l10n(.settingsLaunchAtLoginDescription))
                        .disabled(!(launchAtLoginControl?.isAvailable ?? false) || isUpdatingLaunchAtLogin)
                    }
                }
            }
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard {
                formField(title: l10n(.appearanceModeLabel)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(l10n(.appearanceModeDescription))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 8) {
                            ForEach(AppAppearanceMode.supportedSelections, id: \.self) { mode in
                                appearanceModeRow(mode)
                            }
                        }

                        Text(l10n(.appearanceDefaultNote))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(SelenophileTheme.Colors.tertiaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            settingsCard {
                formField(title: l10n(.themePaletteLabel)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(l10n(.themePaletteDescription))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 8) {
                            ForEach(AppThemePalette.supportedSelections, id: \.self) { palette in
                                themePaletteRow(palette)
                            }
                        }
                    }
                }
            }
        }
    }

    private func appearanceModeRow(_ mode: AppAppearanceMode) -> some View {
        Button {
            selectedAppearanceMode = mode
            appAppearanceStore.preview(mode: mode, palette: selectedThemePalette)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedAppearanceMode == mode ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        selectedAppearanceMode == mode
                            ? SelenophileTheme.Colors.accent
                            : SelenophileTheme.Colors.secondaryText
                    )

                Text(l10n(mode.localizationKey))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .fill(
                        selectedAppearanceMode == mode
                            ? SelenophileTheme.Colors.accent.opacity(0.12)
                            : SelenophileTheme.Colors.inputFill
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .stroke(
                        selectedAppearanceMode == mode
                            ? SelenophileTheme.Colors.accent.opacity(0.45)
                            : SelenophileTheme.Colors.inputBorder,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func themePaletteRow(_ palette: AppThemePalette) -> some View {
        Button {
            selectedThemePalette = palette
            appAppearanceStore.preview(mode: selectedAppearanceMode, palette: palette)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedThemePalette == palette ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        selectedThemePalette == palette
                            ? SelenophileTheme.Colors.accent
                            : SelenophileTheme.Colors.secondaryText
                    )

                Text(l10n(palette.localizationKey))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    ForEach(Array(SelenophileTheme.Colors.previewSwatches(
                        for: palette,
                        colorScheme: selectedAppearanceMode.resolvedColorScheme()
                    ).enumerated()), id: \.offset) { _, swatch in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(swatch)
                            .frame(width: 16, height: 16)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(SelenophileTheme.Colors.border.opacity(0.45), lineWidth: 1)
                            }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .fill(
                        selectedThemePalette == palette
                            ? SelenophileTheme.Colors.accent.opacity(0.12)
                            : SelenophileTheme.Colors.inputFill
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .stroke(
                        selectedThemePalette == palette
                            ? SelenophileTheme.Colors.accent.opacity(0.45)
                            : SelenophileTheme.Colors.inputBorder,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            settingsCard {
                Text("Selenophile")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)

                Text(l10n(.settingsAboutBody))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let updateChecker {
                settingsCard {
                    Text(l10n(.settingsUpdatesTitle))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.primaryText)

                    Button {
                        updateChecker.checkForUpdates()
                    } label: {
                        Label(l10n(.settingsCheckForUpdates), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(SelenophileButtonStyle(kind: .secondary))
                    .disabled(!updateChecker.canCheckForUpdates)
                }
            }

            settingsCard {
                Text(l10n(.settingsAboutDependenciesTitle))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)

                Text(l10n(.settingsAboutDependenciesIntro))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(AboutDependency.allCases, id: \.name) { dependency in
                        dependencyRow(dependency)
                    }
                }
            }
        }
    }

    private func dependencyRow(_ dependency: AboutDependency) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: dependency.symbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SelenophileTheme.Colors.accent)
                .frame(width: 18, height: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Link(dependency.name, destination: dependency.url)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.accent)

                Text(l10n(dependency.descriptionKey))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                .fill(SelenophileTheme.Colors.inputFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                .stroke(SelenophileTheme.Colors.inputBorder, lineWidth: 1)
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

            Button(l10n(.settingsCancel)) {
                onCancel()
            }
            .buttonStyle(SelenophileButtonStyle(kind: .secondary))
            .keyboardShortcut(.cancelAction)
            .disabled(isSaving || isTestingConnection)

            Button(isSaving ? l10n(.settingsSaving) : l10n(.settingsSave)) {
                Task { await submit(closeOnSuccess: true) }
            }
            .buttonStyle(SelenophileButtonStyle(kind: .primary))
            .keyboardShortcut(.defaultAction)
            .disabled(isSaving || isTestingConnection)
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

    private var statusRefreshSlider: some View {
        let selections = PrinterStatusRefreshPolicy.supportedSelections

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(statusRefreshPolicyLabel(selectedStatusRefreshPolicy))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)

                Spacer(minLength: 12)
            }

            Slider(
                value: Binding(
                    get: {
                        Double(selections.firstIndex(of: selectedStatusRefreshPolicy) ?? 0)
                    },
                    set: { value in
                        let index = min(max(Int(value.rounded()), 0), selections.count - 1)
                        selectedStatusRefreshPolicy = selections[index]
                    }
                ),
                in: 0...Double(selections.count - 1),
                step: 1
            )
            .tint(SelenophileTheme.Colors.accent)
            .accessibilityLabel(l10n(.settingsStatusRefreshRateLabel))
            .accessibilityValue(statusRefreshPolicyLabel(selectedStatusRefreshPolicy))

            statusRefreshTickLabels(selections)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                .fill(SelenophileTheme.Colors.inputFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                .stroke(SelenophileTheme.Colors.inputBorder, lineWidth: 1)
        }
    }

    private func statusRefreshPolicyLabel(_ policy: PrinterStatusRefreshPolicy) -> String {
        switch policy {
        case .realtime:
            return l10n(.settingsStatusRefreshRealtime)
        case .seconds(let seconds):
            return String(format: l10n(.settingsStatusRefreshSecondsFormat), seconds)
        }
    }

    private func statusRefreshTickLabel(_ policy: PrinterStatusRefreshPolicy) -> String {
        switch policy {
        case .realtime:
            return l10n(.settingsStatusRefreshRealtime)
        case .seconds(let seconds):
            return "\(seconds)s"
        }
    }

    private func statusRefreshTickLabels(_ selections: [PrinterStatusRefreshPolicy]) -> some View {
        GeometryReader { proxy in
            let thumbCenterInset: CGFloat = 20
            let usableWidth = max(1, proxy.size.width - thumbCenterInset * 2)

            ZStack(alignment: .topLeading) {
                ForEach(Array(selections.enumerated()), id: \.element) { index, policy in
                    let fraction = selections.count <= 1
                        ? CGFloat(0)
                        : CGFloat(index) / CGFloat(selections.count - 1)
                    Text(statusRefreshTickLabel(policy))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            selectedStatusRefreshPolicy == policy
                                ? SelenophileTheme.Colors.primaryText
                                : SelenophileTheme.Colors.tertiaryText
                        )
                        .fixedSize(horizontal: true, vertical: false)
                        .position(
                            x: thumbCenterInset + usableWidth * fraction,
                            y: 9
                        )
                }
            }
            .frame(width: proxy.size.width, height: 18)
        }
        .frame(height: 18)
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

@MainActor
enum SettingsViewSubmission {
    @discardableResult
    static func save(
        store: PrinterStatusStore,
        appAppearanceStore: AppAppearanceStore,
        serverURLString: String,
        apiToken: String,
        cameraSnapshotURL: String,
        appLanguage: AppLanguage,
        appearanceMode: AppAppearanceMode,
        themePalette: AppThemePalette,
        statusRefreshPolicy: PrinterStatusRefreshPolicy
    ) async -> Bool {
        let token = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshotURL = cameraSnapshotURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let success = await store.saveConfiguration(
            serverURLString: serverURLString,
            apiToken: token.isEmpty ? nil : token,
            cameraSnapshotURL: snapshotURL.isEmpty ? nil : snapshotURL,
            appLanguage: appLanguage
        )

        guard success else {
            return false
        }

        appAppearanceStore.save(mode: appearanceMode, palette: themePalette)
        store.statusRefreshPolicy = statusRefreshPolicy
        return true
    }
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
    case about

    var symbolName: String {
        switch self {
        case .connection:
            return "link"
        case .general:
            return "gearshape"
        case .appearance:
            return "paintpalette"
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
        case .about:
            return AppLocalization.localizedString(.settingsAboutSection, language: language)
        }
    }
}

private enum AboutDependency: CaseIterable {
    case swift
    case swiftUI
    case appKit
    case sparkle
    case widgetKit
    case serviceManagement
    case moonraker
    case tuist

    var name: String {
        switch self {
        case .swift:
            return "Swift / Swift Package Manager"
        case .swiftUI:
            return "SwiftUI"
        case .appKit:
            return "AppKit"
        case .sparkle:
            return "Sparkle 2"
        case .widgetKit:
            return "WidgetKit"
        case .serviceManagement:
            return "ServiceManagement"
        case .moonraker:
            return "Moonraker API"
        case .tuist:
            return "Tuist"
        }
    }

    var symbolName: String {
        switch self {
        case .swift, .swiftUI:
            return "swift"
        case .appKit:
            return "macwindow"
        case .sparkle:
            return "arrow.triangle.2.circlepath"
        case .widgetKit:
            return "rectangle.grid.2x2"
        case .serviceManagement:
            return "power"
        case .moonraker:
            return "network"
        case .tuist:
            return "hammer"
        }
    }

    var url: URL {
        switch self {
        case .swift:
            return URL(string: "https://www.swift.org/package-manager/")!
        case .swiftUI:
            return URL(string: "https://developer.apple.com/documentation/swiftui")!
        case .appKit:
            return URL(string: "https://developer.apple.com/documentation/appkit")!
        case .sparkle:
            return URL(string: "https://sparkle-project.org/")!
        case .widgetKit:
            return URL(string: "https://developer.apple.com/documentation/widgetkit")!
        case .serviceManagement:
            return URL(string: "https://developer.apple.com/documentation/servicemanagement")!
        case .moonraker:
            return URL(string: "https://moonraker.readthedocs.io/")!
        case .tuist:
            return URL(string: "https://tuist.dev/")!
        }
    }

    var descriptionKey: AppLocalization.Key {
        switch self {
        case .swift:
            return .settingsDependencySwift
        case .swiftUI:
            return .settingsDependencySwiftUI
        case .appKit:
            return .settingsDependencyAppKit
        case .sparkle:
            return .settingsDependencySparkle
        case .widgetKit:
            return .settingsDependencyWidgetKit
        case .serviceManagement:
            return .settingsDependencyServiceManagement
        case .moonraker:
            return .settingsDependencyMoonraker
        case .tuist:
            return .settingsDependencyTuist
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
        button.contentTintColor = .labelColor
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
