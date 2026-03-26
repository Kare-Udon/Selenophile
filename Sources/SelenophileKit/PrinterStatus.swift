import Foundation

public struct TemperatureStatus: Equatable, Sendable {
    public var actual: Double
    public var target: Double

    public init(actual: Double, target: Double) {
        self.actual = actual
        self.target = target
    }
}

public struct LayerStatus: Equatable, Sendable {
    public var current: Int
    public var total: Int?

    public init(current: Int, total: Int?) {
        self.current = current
        self.total = total
    }
}

public enum PrinterState: String, Codable, Equatable, Sendable {
    case standby
    case printing
    case paused
    case complete
    case cancelled
    case error
    case unknown

    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "standby", "ready":
            self = .standby
        case "printing":
            self = .printing
        case "paused":
            self = .paused
        case "complete", "completed":
            self = .complete
        case "cancelled", "canceled":
            self = .cancelled
        case "error":
            self = .error
        default:
            self = .unknown
        }
    }

    public var localizedLabel: String {
        switch self {
        case .standby:
            return "待机"
        case .printing:
            return "打印中"
        case .paused:
            return "已暂停"
        case .complete:
            return "已完成"
        case .cancelled:
            return "已取消"
        case .error:
            return "错误"
        case .unknown:
            return "未知"
        }
    }
}

public struct PrinterStatus: Equatable, Sendable {
    public var state: PrinterState
    public var filename: String?
    public var message: String?
    public var progress: Double?
    public var printDuration: TimeInterval?
    public var estimatedTimeRemaining: TimeInterval?
    public var slicerEstimatedPrintTime: TimeInterval?
    public var layer: LayerStatus?
    public var bed: TemperatureStatus?
    public var extruder: TemperatureStatus?
    public var feedRateMultiplier: Double?

    public init(
        state: PrinterState = .standby,
        filename: String? = nil,
        message: String? = nil,
        progress: Double? = nil,
        printDuration: TimeInterval? = nil,
        estimatedTimeRemaining: TimeInterval? = nil,
        slicerEstimatedPrintTime: TimeInterval? = nil,
        layer: LayerStatus? = nil,
        bed: TemperatureStatus? = nil,
        extruder: TemperatureStatus? = nil,
        feedRateMultiplier: Double? = nil
    ) {
        self.state = state
        self.filename = filename
        self.message = message
        self.progress = progress
        self.printDuration = printDuration
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.slicerEstimatedPrintTime = slicerEstimatedPrintTime
        self.layer = layer
        self.bed = bed
        self.extruder = extruder
        self.feedRateMultiplier = feedRateMultiplier
    }

    public var normalizedProgress: Double {
        guard let progress else { return 0 }
        return min(max(progress, 0), 1)
    }

    public func applying(delta: PrinterStatusDelta) -> PrinterStatus {
        PrinterStatus(
            state: delta.state ?? state,
            filename: delta.filename ?? filename,
            message: delta.message ?? message,
            progress: delta.progress ?? progress,
            printDuration: delta.printDuration ?? printDuration,
            estimatedTimeRemaining: delta.estimatedTimeRemaining ?? estimatedTimeRemaining,
            slicerEstimatedPrintTime: slicerEstimatedPrintTime,
            layer: delta.layer ?? layer,
            bed: delta.bed ?? bed,
            extruder: delta.extruder ?? extruder,
            feedRateMultiplier: delta.feedRateMultiplier ?? feedRateMultiplier
        )
    }
}

public struct PrinterStatusDelta: Equatable, Sendable {
    public var state: PrinterState?
    public var filename: String?
    public var message: String?
    public var progress: Double?
    public var printDuration: TimeInterval?
    public var estimatedTimeRemaining: TimeInterval?
    public var layer: LayerStatus?
    public var bed: TemperatureStatus?
    public var extruder: TemperatureStatus?
    public var feedRateMultiplier: Double?

    public init(
        state: PrinterState? = nil,
        filename: String? = nil,
        message: String? = nil,
        progress: Double? = nil,
        printDuration: TimeInterval? = nil,
        estimatedTimeRemaining: TimeInterval? = nil,
        layer: LayerStatus? = nil,
        bed: TemperatureStatus? = nil,
        extruder: TemperatureStatus? = nil,
        feedRateMultiplier: Double? = nil
    ) {
        self.state = state
        self.filename = filename
        self.message = message
        self.progress = progress
        self.printDuration = printDuration
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.layer = layer
        self.bed = bed
        self.extruder = extruder
        self.feedRateMultiplier = feedRateMultiplier
    }
}
