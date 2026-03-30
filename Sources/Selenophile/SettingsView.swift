import SwiftUI
import SelenophileKit

struct SettingsView: View {
    let store: PrinterStatusStore
    let onClose: () -> Void
    let launchAtLoginControl: LaunchAtLoginControl?

    @State private var serverURLString: String
    @State private var apiToken: String
    @State private var cameraSnapshotURL: String
    @State private var launchAtLoginEnabled: Bool
    @State private var isUpdatingLaunchAtLogin = false
    @State private var isSaving = false

    init(
        store: PrinterStatusStore,
        onClose: @escaping () -> Void,
        launchAtLoginControl: LaunchAtLoginControl? = nil
    ) {
        self.store = store
        self.onClose = onClose
        self.launchAtLoginControl = launchAtLoginControl
        _serverURLString = State(initialValue: store.configuration?.serverURLString ?? "http://127.0.0.1:7125")
        _apiToken = State(initialValue: store.configuration?.apiToken ?? "")
        _cameraSnapshotURL = State(initialValue: store.configuration?.cameraSnapshotURL ?? "")
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
                : cameraSnapshotURL.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        isSaving = false
        if success {
            onClose()
        }
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
            Text("Moonraker Setup")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.68))
                .textCase(.uppercase)
                .tracking(2)

            Text("连接你的打印状态源")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("输入 Moonraker 地址、可选令牌和相机快照地址，保存后会立即测试连接。")
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
                Text("Moonraker URL")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                TextField("http://127.0.0.1:7125", text: $serverURLString)
                    .textFieldStyle(SetupFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("API Token（可选）")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                SecureField("JWT 或 API key", text: $apiToken)
                    .textFieldStyle(SetupFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("相机快照 URL")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                TextField("http://127.0.0.1/webcam/?action=snapshot", text: $cameraSnapshotURL)
                    .textFieldStyle(SetupFieldStyle())
                Text("填写一个可以直接返回图片的地址。支持绝对 URL，也支持相对当前 Moonraker 主机的路径。")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.49, blue: 0.56))
                    .fixedSize(horizontal: false, vertical: true)
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
                    Text("开机自启")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.18))

                    Text("启用后，应用会在系统登录时自动打开。")
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
                Text("当前不可用")
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

            Button("取消") {
                onClose()
            }
            .buttonStyle(SetupActionButtonStyle(kind: .secondary))
            .disabled(isSaving && store.configuration == nil)

            Button(isSaving ? "连接中…" : "测试连接并保存") {
                Task { await save() }
            }
            .buttonStyle(SetupActionButtonStyle(kind: .primary))
            .keyboardShortcut(.defaultAction)
            .disabled(isSaving)
        }
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
