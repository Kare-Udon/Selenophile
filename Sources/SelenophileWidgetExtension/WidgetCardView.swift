import SwiftUI
import WidgetKit
import SelenophileKit

struct WidgetCardView: View {
    let snapshot: WidgetSnapshot
    let family: WidgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: familySpacing) {
            header
            titleBlock
            progressBlock
            metricsBlock
            summaryBlock
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(cardBackground)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(snapshot.statusLabel)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundStyle(tone.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(tone.statusBackground, in: Capsule())

            Spacer(minLength: 8)

            if showsConnectionLabel {
                Text(snapshot.connectionLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(tone.secondaryText)
            }
        }
    }

    private var titleBlock: some View {
        Text(snapshot.title)
            .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(tone.primaryText)
            .lineLimit(family == .systemSmall ? 2 : 1)
            .minimumScaleFactor(0.88)
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snapshot.progressLabel)
                .font(.system(size: progressFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(tone.primaryText)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.08))
                    Capsule()
                        .fill(tone.progressGradient)
                        .frame(width: max(proxy.size.width * snapshot.progress, 10))
                }
            }
            .frame(height: progressBarHeight)
        }
    }

    @ViewBuilder
    private var metricsBlock: some View {
        if family == .systemSmall {
            EmptyView()
        } else {
            let metrics = metricsForFamily
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: metricGridSpacing),
                    count: metricsColumns
                ),
                spacing: metricGridSpacing
            ) {
                ForEach(metrics, id: \.title) { metric in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(metric.title)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(tone.secondaryText)
                        Text(metric.value)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(tone.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(metricBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var summaryBlock: some View {
        Text(snapshot.summary)
            .font(.system(size: family == .systemSmall ? 11 : 12, weight: .medium, design: .rounded))
            .foregroundStyle(tone.secondaryText)
            .lineLimit(family == .systemLarge ? 2 : 1)
    }

    private var familySpacing: CGFloat {
        switch family {
        case .systemSmall:
            return 10
        case .systemMedium:
            return 12
        case .systemLarge:
            return 14
        default:
            return 12
        }
    }

    private var contentPadding: CGFloat {
        switch family {
        case .systemSmall:
            return 14
        case .systemMedium:
            return 16
        case .systemLarge:
            return 18
        default:
            return 16
        }
    }

    private var titleFontSize: CGFloat {
        switch family {
        case .systemSmall:
            return 16
        case .systemMedium:
            return 18
        case .systemLarge:
            return 20
        default:
            return 18
        }
    }

    private var progressFontSize: CGFloat {
        switch family {
        case .systemSmall:
            return 24
        case .systemMedium:
            return 28
        case .systemLarge:
            return 32
        default:
            return 28
        }
    }

    private var progressBarHeight: CGFloat {
        family == .systemSmall ? 7 : 8
    }

    private var metricGridSpacing: CGFloat {
        family == .systemLarge ? 8 : 10
    }

    private var metricsColumns: Int {
        switch family {
        case .systemSmall:
            return 0
        case .systemMedium:
            return 3
        case .systemLarge:
            return 5
        default:
            return 3
        }
    }

    private var showsConnectionLabel: Bool {
        family != .systemSmall
    }

    private var metricsForFamily: [Metric] {
        switch family {
        case .systemSmall:
            return []
        case .systemMedium:
            return [
                Metric(title: l10n(.menuNozzle), value: snapshot.nozzle),
                Metric(title: l10n(.menuBed), value: snapshot.bed),
                Metric(title: l10n(.menuRemainingTime), value: snapshot.remainingTime)
            ]
        case .systemLarge:
            return [
                Metric(title: l10n(.menuNozzle), value: snapshot.nozzle),
                Metric(title: l10n(.menuBed), value: snapshot.bed),
                Metric(title: l10n(.menuRemainingTime), value: snapshot.remainingTime),
                Metric(title: l10n(.menuLayer), value: snapshot.layer),
                Metric(title: l10n(.menuPrintSpeed), value: snapshot.speed)
            ]
        default:
            return [
                Metric(title: l10n(.menuNozzle), value: snapshot.nozzle),
                Metric(title: l10n(.menuBed), value: snapshot.bed),
                Metric(title: l10n(.menuRemainingTime), value: snapshot.remainingTime)
            ]
        }
    }

    private func l10n(_ key: AppLocalization.Key) -> String {
        AppLocalization.localizedString(key, language: snapshot.language)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.76))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var metricBackground: Color {
        Color.white.opacity(0.72)
    }

    private var tone: TonePalette {
        TonePalette(snapshot.tone)
    }

    private struct Metric {
        let title: String
        let value: String
    }
}

private struct TonePalette {
    let primaryText: Color
    let secondaryText: Color
    let statusBackground: Color
    let progressGradient: LinearGradient

    init(_ tone: WidgetTone) {
        switch tone {
        case .accent:
            primaryText = Color(red: 0.09, green: 0.12, blue: 0.18)
            secondaryText = Color(red: 0.38, green: 0.43, blue: 0.50)
            statusBackground = Color(red: 1.0, green: 0.88, blue: 0.79)
            progressGradient = LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.55, blue: 0.33),
                    Color(red: 1.0, green: 0.71, blue: 0.40)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .muted:
            primaryText = Color(red: 0.10, green: 0.14, blue: 0.20)
            secondaryText = Color(red: 0.44, green: 0.49, blue: 0.56)
            statusBackground = Color(red: 0.90, green: 0.93, blue: 0.96)
            progressGradient = LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.34, blue: 0.44),
                    Color(red: 0.48, green: 0.54, blue: 0.64)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .danger:
            primaryText = Color(red: 0.18, green: 0.09, blue: 0.08)
            secondaryText = Color(red: 0.52, green: 0.22, blue: 0.20)
            statusBackground = Color(red: 0.98, green: 0.87, blue: 0.85)
            progressGradient = LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.35, blue: 0.32),
                    Color(red: 0.94, green: 0.56, blue: 0.44)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .neutral:
            primaryText = Color(red: 0.12, green: 0.15, blue: 0.21)
            secondaryText = Color(red: 0.47, green: 0.51, blue: 0.58)
            statusBackground = Color(red: 0.91, green: 0.92, blue: 0.94)
            progressGradient = LinearGradient(
                colors: [
                    Color(red: 0.54, green: 0.58, blue: 0.65),
                    Color(red: 0.66, green: 0.70, blue: 0.77)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
