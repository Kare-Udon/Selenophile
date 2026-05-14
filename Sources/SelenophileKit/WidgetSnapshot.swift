import Foundation

public enum WidgetTone: String, Codable, Equatable, Sendable {
    case accent
    case muted
    case danger
    case neutral
}

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public var language: AppLanguage
    public var statusLabel: String
    public var connectionLabel: String
    public var title: String
    public var progress: Double
    public var progressLabel: String
    public var remainingTime: String
    public var elapsedTime: String
    public var nozzle: String
    public var bed: String
    public var layer: String
    public var speed: String
    public var summary: String
    public var tone: WidgetTone

    public init(
        language: AppLanguage = .system,
        statusLabel: String,
        connectionLabel: String,
        title: String,
        progress: Double,
        progressLabel: String,
        remainingTime: String,
        elapsedTime: String,
        nozzle: String,
        bed: String,
        layer: String,
        speed: String,
        summary: String,
        tone: WidgetTone
    ) {
        self.language = language
        self.statusLabel = statusLabel
        self.connectionLabel = connectionLabel
        self.title = title
        self.progress = progress
        self.progressLabel = progressLabel
        self.remainingTime = remainingTime
        self.elapsedTime = elapsedTime
        self.nozzle = nozzle
        self.bed = bed
        self.layer = layer
        self.speed = speed
        self.summary = summary
        self.tone = tone
    }

    private enum CodingKeys: String, CodingKey {
        case language
        case statusLabel
        case connectionLabel
        case title
        case progress
        case progressLabel
        case remainingTime
        case elapsedTime
        case nozzle
        case bed
        case layer
        case speed
        case summary
        case tone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        self.statusLabel = try container.decode(String.self, forKey: .statusLabel)
        self.connectionLabel = try container.decode(String.self, forKey: .connectionLabel)
        self.title = try container.decode(String.self, forKey: .title)
        self.progress = try container.decode(Double.self, forKey: .progress)
        self.progressLabel = try container.decode(String.self, forKey: .progressLabel)
        self.remainingTime = try container.decode(String.self, forKey: .remainingTime)
        self.elapsedTime = try container.decode(String.self, forKey: .elapsedTime)
        self.nozzle = try container.decode(String.self, forKey: .nozzle)
        self.bed = try container.decode(String.self, forKey: .bed)
        self.layer = try container.decode(String.self, forKey: .layer)
        self.speed = try container.decode(String.self, forKey: .speed)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.tone = try container.decode(WidgetTone.self, forKey: .tone)
    }

    public static var placeholder: WidgetSnapshot {
        placeholder(language: .system)
    }

    public static func placeholder(language: AppLanguage) -> WidgetSnapshot {
        WidgetSnapshot(
            language: language,
            statusLabel: AppLocalization.localizedString(.menuConnectionBadgeUnconfigured, language: language),
            connectionLabel: AppLocalization.localizedString(.menuConnectionBadgeUnconfigured, language: language),
            title: AppLocalization.localizedString(.widgetTitleUnconfigured, language: language),
            progress: 0,
            progressLabel: "0%",
            remainingTime: "--:--:--",
            elapsedTime: "--:--:--",
            nozzle: "--",
            bed: "--",
            layer: "--",
            speed: "--",
            summary: AppLocalization.localizedString(.widgetSummaryUnconfigured, language: language),
            tone: .neutral
        )
    }
}

enum WidgetSnapshotFormatter {
    static let missingText = "--"

    static func percentLabel(for progress: Double?) -> String {
        guard let progress else { return "0%" }
        return "\(Int((clamped(progress) * 100).rounded()))%"
    }

    static func clockString(for interval: TimeInterval?) -> String {
        guard let interval else { return "--:--:--" }
        let totalSeconds = max(0, Int(interval.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func temperatureString(for status: TemperatureStatus?) -> String {
        guard let status else { return missingText }
        return String(format: "%.1f / %.1f°C", status.actual, status.target)
    }

    static func layerString(for layer: LayerStatus?) -> String {
        guard let layer else { return missingText }
        if let total = layer.total {
            return "\(layer.current) / \(total)"
        }
        return "\(layer.current)"
    }

    static func feedRateString(for multiplier: Double?) -> String {
        guard let multiplier else { return missingText }
        return "\(Int((clamped(multiplier) * 100).rounded()))%"
    }

    static func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
