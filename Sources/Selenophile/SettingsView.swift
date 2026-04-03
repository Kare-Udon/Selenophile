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
        VStack(alignment: .leading, spacing: 18) {
            heroCard
            formCard
            launchAtLoginCard
            if let error = store.displayErrorMessage, !error.isEmpty {
                errorBanner(error)
            }
            actions
        }
        .padding(22)
        .frame(width: 460)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.969, green: 0.976, blue: 0.992),
                    Color(red: 0.925, green: 0.941, blue: 0.972)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            refreshLaunchAtLoginState()
            onLanguageSelectionPreview(selectedAppLanguage)
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
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
        if success {
            onClose()
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

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(l10n(.settingsHeroBadge))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.68))
                .textCase(.uppercase)
                .tracking(2)

            Text(l10n(.settingsHeroTitle))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(l10n(.settingsHeroSubtitle))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.10, blue: 0.15),
                            Color(red: 0.16, green: 0.27, blue: 0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(l10n(.settingsMoonrakerURLLabel))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                TextField(l10n(.settingsMoonrakerURLPlaceholder), text: $serverURLString)
                    .textFieldStyle(SetupFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(l10n(.settingsAPITokenLabel))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                SecureField(l10n(.settingsAPITokenPlaceholder), text: $apiToken)
                    .textFieldStyle(SetupFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(l10n(.settingsCameraSnapshotURLLabel))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                TextField(l10n(.settingsCameraSnapshotURLPlaceholder), text: $cameraSnapshotURL)
                    .textFieldStyle(SetupFieldStyle())
                Text(l10n(.settingsCameraSnapshotHelp))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.49, blue: 0.56))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(l10n(.settingsLanguageLabel))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                languagePicker
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 10)
        )
    }

    private var launchAtLoginCard: some View {
        let isAvailable = launchAtLoginControl?.isAvailable ?? false

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(l10n(.settingsLaunchAtLoginLabel))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.18))

                    Text(l10n(.settingsLaunchAtLoginDescription))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.45, green: 0.49, blue: 0.56))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Toggle("", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { newValue in
                        Task { await updateLaunchAtLoginEnabled(newValue) }
                    }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle())
                .disabled(!isAvailable || isUpdatingLaunchAtLogin)
            }

            if !isAvailable {
                Text(l10n(.settingsLaunchAtLoginUnavailable))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.58, green: 0.62, blue: 0.69))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 10)
        )
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(red: 0.78, green: 0.18, blue: 0.14))
            Text(error)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.52, green: 0.10, blue: 0.10))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.99, green: 0.93, blue: 0.92))
        )
    }

    private var actions: some View {
        HStack {
            Spacer()

            Button(l10n(.settingsCancel)) {
                onCancel()
            }
            .buttonStyle(SetupActionButtonStyle(kind: .secondary))
            .disabled(isSaving && store.configuration == nil)

            Button(isSaving ? l10n(.settingsSaving) : l10n(.settingsSave)) {
                Task { await save() }
            }
            .buttonStyle(SetupActionButtonStyle(kind: .primary))
            .keyboardShortcut(.defaultAction)
            .disabled(isSaving)
        }
    }

    private var languagePicker: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.82, green: 0.86, blue: 0.92), lineWidth: 1)

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
                .foregroundStyle(Color(red: 0.45, green: 0.49, blue: 0.56))
                .padding(.trailing, 14)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
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

private struct SetupFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.18))
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.82, green: 0.86, blue: 0.92), lineWidth: 1)
            }
    }
}

private struct SetupActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(kind == .primary ? Color.white : Color(red: 0.07, green: 0.10, blue: 0.15))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(background(configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private func background(_ isPressed: Bool) -> AnyView {
        switch kind {
        case .primary:
            return AnyView(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isPressed
                            ? Color(red: 0.05, green: 0.08, blue: 0.13)
                            : Color(red: 0.07, green: 0.10, blue: 0.15)
                    )
            )
        case .secondary:
            return AnyView(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isPressed ? Color.white.opacity(0.72) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
            )
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
        button.contentTintColor = NSColor(
            calibratedRed: 0.11,
            green: 0.14,
            blue: 0.18,
            alpha: 1
        )
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
