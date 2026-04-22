import AppKit
import SwiftUI
import SelenophileKit

struct LogView: View {
    let logStore: AppLogStore
    let appLanguageStore: AppLanguageStore

    @AppStorage("log.minimumLevel") private var minimumLevelRawValue: String = AppLogLevel.info.rawValue

    private let timeColumnWidth: CGFloat = 88
    private let levelColumnWidth: CGFloat = 82
    private let sourceColumnWidth: CGFloat = 132

    private var uiLanguage: AppLanguage {
        appLanguageStore.selectedLanguage.resolved(preferredLanguages: Locale.preferredLanguages)
    }

    private func l10n(_ key: AppLocalization.Key) -> String {
        AppLocalization.localizedString(key, language: uiLanguage)
    }

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
            toolbar
            tableCard
        }
        .padding(22)
        .frame(minWidth: 920, minHeight: 520)
        .background {
            SelenophileWindowBackground()
        }
    }

    private var toolbar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 12) {
                CircleTrafficLights()

                HStack(spacing: 8) {
                    Text(l10n(.logLevelLabel))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)

                    Picker("", selection: minimumLevelBinding) {
                        ForEach(AppLogLevel.allCases, id: \.self) { level in
                            Text(level.displayName(in: uiLanguage)).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 124)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .selenophileCard(
                    cornerRadius: SelenophileTheme.Metrics.smallCorner,
                    fill: SelenophileTheme.Colors.surfaceRaised
                )
            }

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                Button {
                    copyAllLogs()
                } label: {
                    Label(l10n(.logCopyAll), systemImage: "doc.on.doc")
                }
                .buttonStyle(SelenophileButtonStyle(kind: .secondary))
                .disabled(logStore.entries.isEmpty)

                Button {
                    logStore.clear()
                } label: {
                    Label(l10n(.logClear), systemImage: "trash")
                }
                .buttonStyle(SelenophileButtonStyle(kind: .destructive))
                .disabled(logStore.entries.isEmpty)
            }
        }
    }

    private var tableCard: some View {
        VStack(spacing: 0) {
            headerRow

            Divider()
                .overlay(SelenophileTheme.Colors.divider)

            if logStore.entries.isEmpty {
                emptyState(
                    symbol: "text.append",
                    title: l10n(.logEmptyStateTitle),
                    subtitle: l10n(.logEmptyStateSubtitle)
                )
            } else if visibleEntries.isEmpty {
                emptyState(
                    symbol: "line.3.horizontal.decrease.circle",
                    title: l10n(.logFilteredEmptyStateTitle),
                    subtitle: l10n(.logFilteredEmptyStateSubtitle)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(visibleEntries) { entry in
                            logRow(entry)
                            Divider()
                                .overlay(SelenophileTheme.Colors.divider)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .selenophileCard()
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell(l10n(.logTimeColumn), width: timeColumnWidth)
            headerCell(l10n(.logLevelLabel), width: levelColumnWidth)
            headerCell(l10n(.logSourceColumn), width: sourceColumnWidth)
            headerCell(l10n(.logMessageColumn), width: nil)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(SelenophileTheme.Colors.surfaceRaised)
    }

    private func headerCell(_ text: String, width: CGFloat?) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(SelenophileTheme.Colors.secondaryText)
            .textCase(.uppercase)
            .tracking(1.4)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private func emptyState(symbol: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)

            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 80)
    }

    private func logRow(_ entry: AppLogEntry) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(entry.timestamp.logTimestamp)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                .frame(width: timeColumnWidth, alignment: .leading)

            Text(entry.level.displayName(in: uiLanguage))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(entry.level.foregroundColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(entry.level.backgroundColor, in: Capsule())
                .frame(width: levelColumnWidth, alignment: .leading)

            Text(entry.source)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)
                .frame(width: sourceColumnWidth, alignment: .leading)

            Text(entry.message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.clear)
    }

    private func copyAllLogs() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logStore.exportText(), forType: .string)
    }

    private var minimumLevelBinding: Binding<AppLogLevel> {
        Binding(
            get: { minimumLevel },
            set: { minimumLevel = $0 }
        )
    }
}

private struct CircleTrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.33))
            Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.21))
            Circle().fill(Color(red: 0.17, green: 0.80, blue: 0.35))
        }
        .frame(width: 46, alignment: .leading)
    }
}

private extension AppLogLevel {
    static var allCases: [AppLogLevel] {
        [.debug, .info, .warning, .error]
    }

    func displayName(in uiLanguage: AppLanguage) -> String {
        switch self {
        case .debug:
            return AppLocalization.localizedString(.logLevelDebug, language: uiLanguage)
        case .info:
            return AppLocalization.localizedString(.logLevelInfo, language: uiLanguage)
        case .warning:
            return AppLocalization.localizedString(.logLevelWarning, language: uiLanguage)
        case .error:
            return AppLocalization.localizedString(.logLevelError, language: uiLanguage)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .debug:
            return Color(red: 0.45, green: 0.78, blue: 1.0)
        case .info:
            return SelenophileTheme.Colors.success
        case .warning:
            return SelenophileTheme.Colors.warning
        case .error:
            return SelenophileTheme.Colors.danger
        }
    }

    var backgroundColor: Color {
        switch self {
        case .debug:
            return Color(red: 0.13, green: 0.31, blue: 0.45)
        case .info:
            return Color(red: 0.16, green: 0.31, blue: 0.21)
        case .warning:
            return Color(red: 0.34, green: 0.24, blue: 0.09)
        case .error:
            return Color(red: 0.38, green: 0.16, blue: 0.16)
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
