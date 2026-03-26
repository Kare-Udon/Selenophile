import Foundation

public enum WidgetTone: String, Codable, Equatable, Sendable {
    case accent
    case muted
    case danger
    case neutral
}

public struct WidgetSnapshot: Codable, Equatable, Sendable {
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

    public static var placeholder: WidgetSnapshot {
        WidgetSnapshot(
            statusLabel: "未配置",
            connectionLabel: "待配置",
            title: "请先设置 Moonraker 地址",
            progress: 0,
            progressLabel: "0%",
            remainingTime: "--:--:--",
            elapsedTime: "--:--:--",
            nozzle: "--",
            bed: "--",
            layer: "--",
            speed: "--",
            summary: "还没有可用的打印状态数据",
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
