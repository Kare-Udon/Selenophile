import AppKit
import SwiftUI
import SelenophileKit

struct LogView: View {
    let logStore: AppLogStore
    @AppStorage("log.minimumLevel") private var minimumLevelRawValue: String = AppLogLevel.info.rawValue

    private var minimumLevel: AppLogLevel {
        get {
            AppLogLevel(rawValue: minimumLevelRawValue) ?? .info
        }
        nonmutating set {
            minimumLevelRawValue = newValue.rawValue
        }
    }

    private var visibleEntries: [AppLogEntry] {
        logStore.visibleEntries(minimumLevel: minimumLevel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            logList
        }
        .padding(18)
        .frame(minWidth: 640, minHeight: 420)
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("调试日志")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))

                    Text("显示应用内部的连接、重试、状态更新与相机请求日志。")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("日志等级")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))

                        Picker("", selection: minimumLevelBinding) {
                            ForEach(AppLogLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(minWidth: 120, alignment: .leading)
                    }

                    HStack(spacing: 8) {
                        Button("复制全部") {
                            copyAllLogs()
                        }
                        .buttonStyle(LogActionButtonStyle(kind: .secondary))
                        .disabled(logStore.entries.isEmpty)

                        Button("清空") {
                            logStore.clear()
                        }
                        .buttonStyle(LogActionButtonStyle(kind: .primary))
                        .disabled(logStore.entries.isEmpty)
                    }
                }
            }

            Text(countSummary)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
        }
        .padding(18)
        .background(logCardBackground)
    }

    private var logList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if logStore.entries.isEmpty {
                    emptyState
                } else if visibleEntries.isEmpty {
                    filteredEmptyState
                } else {
                    ForEach(visibleEntries) { entry in
                        logRow(entry)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.append")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))

            Text("当前还没有日志")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.14, green: 0.17, blue: 0.22))

            Text("应用开始记录连接或相机事件后，会在这里实时显示。")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 72)
        .background(logCardBackground)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))

            Text("当前等级下没有日志")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.14, green: 0.17, blue: 0.22))

            Text("调整最低显示等级后，可以看到更多日志。")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 72)
        .background(logCardBackground)
    }

    private func logRow(_ entry: AppLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(entry.timestamp.logTimestamp)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))

                Text(entry.level.label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.level.foregroundColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(entry.level.backgroundColor, in: Capsule())

                Text(entry.source)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))

                Spacer(minLength: 0)
            }

            Text(entry.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(logCardBackground)
    }

    private var logCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.white.opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func copyAllLogs() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logStore.exportText(), forType: .string)
    }

    private var countSummary: String {
        if logStore.entries.isEmpty {
            return "当前共 0 条"
        }
        if visibleEntries.count == logStore.entries.count {
            return "当前共 \(logStore.entries.count) 条"
        }
        return "当前显示 \(visibleEntries.count) / 共 \(logStore.entries.count) 条"
    }

    private var minimumLevelBinding: Binding<AppLogLevel> {
        Binding(
            get: { minimumLevel },
            set: { minimumLevel = $0 }
        )
    }
}

private struct LogActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(kind == .primary ? Color.white : Color(red: 0.07, green: 0.10, blue: 0.15))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(background(configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private func background(_ isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                kind == .primary
                ? (isPressed ? Color(red: 0.67, green: 0.24, blue: 0.14) : Color(red: 0.78, green: 0.18, blue: 0.14))
                : (isPressed ? Color.white.opacity(0.72) : Color.white)
            )
            .shadow(color: kind == .secondary ? Color.black.opacity(0.06) : .clear, radius: 10, x: 0, y: 6)
    }
}

private extension AppLogLevel {
    static var allCases: [AppLogLevel] {
        [.debug, .info, .warning, .error]
    }

    var displayName: String {
        switch self {
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        }
    }

    var label: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARN"
        case .error:
            return "ERROR"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .debug:
            return Color(red: 0.18, green: 0.36, blue: 0.66)
        case .info:
            return Color(red: 0.07, green: 0.10, blue: 0.15)
        case .warning:
            return Color(red: 0.55, green: 0.34, blue: 0.05)
        case .error:
            return Color(red: 0.78, green: 0.18, blue: 0.14)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .debug:
            return Color(red: 0.88, green: 0.93, blue: 1.0)
        case .info:
            return Color.black.opacity(0.08)
        case .warning:
            return Color(red: 1.0, green: 0.93, blue: 0.80)
        case .error:
            return Color(red: 0.99, green: 0.90, blue: 0.88)
        }
    }
}

private extension Date {
    var logTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
}
