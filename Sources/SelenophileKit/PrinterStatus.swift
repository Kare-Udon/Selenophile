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

struct TemperatureStatusPatch: Equatable, Sendable {
    var actual: Double?
    var target: Double?

    init(actual: Double?, target: Double?) {
        self.actual = actual
        self.target = target
    }

    init(status: TemperatureStatus) {
        self.actual = status.actual
        self.target = status.target
    }

    func applying(to status: TemperatureStatus?) -> TemperatureStatus? {
        let actual = actual ?? status?.actual
        let target = target ?? status?.target
        guard let actual, let target else { return status }
        return TemperatureStatus(actual: actual, target: target)
    }
}

struct LayerStatusPatch: Equatable, Sendable {
    var current: Int?
    var total: Int?

    init(current: Int?, total: Int?) {
        self.current = current
        self.total = total
    }

    init(status: LayerStatus) {
        self.current = status.current
        self.total = status.total
    }

    func applying(to status: LayerStatus?) -> LayerStatus? {
        let current = current ?? status?.current
        let total = total ?? status?.total
        guard let current else { return status }
        return LayerStatus(current: current, total: total)
    }
}

struct PrinterStatusClearedFields: OptionSet, Equatable, Sendable {
    let rawValue: Int

    static let filename = PrinterStatusClearedFields(rawValue: 1 << 0)
    static let message = PrinterStatusClearedFields(rawValue: 1 << 1)
    static let progress = PrinterStatusClearedFields(rawValue: 1 << 2)
    static let printDuration = PrinterStatusClearedFields(rawValue: 1 << 3)
    static let estimatedTimeRemaining = PrinterStatusClearedFields(rawValue: 1 << 4)
    static let layer = PrinterStatusClearedFields(rawValue: 1 << 5)
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

    var clearsPrintJobFields: Bool {
        switch self {
        case .standby, .complete, .cancelled:
            return true
        case .printing, .paused, .error, .unknown:
            return false
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
            filename: delta.clearedFields.contains(.filename) ? nil : delta.filename ?? filename,
            message: delta.clearedFields.contains(.message) ? nil : delta.message ?? message,
            progress: delta.clearedFields.contains(.progress) ? nil : delta.progress ?? progress,
            printDuration: delta.clearedFields.contains(.printDuration) ? nil : delta.printDuration ?? printDuration,
            estimatedTimeRemaining: delta.clearedFields.contains(.estimatedTimeRemaining)
                ? nil
                : delta.estimatedTimeRemaining ?? estimatedTimeRemaining,
            slicerEstimatedPrintTime: slicerEstimatedPrintTime,
            layer: delta.clearedFields.contains(.layer) ? nil : delta.layerPatch?.applying(to: layer) ?? delta.layer ?? layer,
            bed: delta.bedPatch?.applying(to: bed) ?? delta.bed ?? bed,
            extruder: delta.extruderPatch?.applying(to: extruder) ?? delta.extruder ?? extruder,
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
    var layerPatch: LayerStatusPatch?
    var bedPatch: TemperatureStatusPatch?
    var extruderPatch: TemperatureStatusPatch?
    var clearedFields: PrinterStatusClearedFields

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
        self.init(
            state: state,
            filename: filename,
            message: message,
            progress: progress,
            printDuration: printDuration,
            estimatedTimeRemaining: estimatedTimeRemaining,
            layer: layer,
            bed: bed,
            extruder: extruder,
            feedRateMultiplier: feedRateMultiplier,
            layerPatch: layer.map(LayerStatusPatch.init(status:)),
            bedPatch: bed.map(TemperatureStatusPatch.init(status:)),
            extruderPatch: extruder.map(TemperatureStatusPatch.init(status:)),
            clearedFields: []
        )
    }

    init(
        state: PrinterState? = nil,
        filename: String? = nil,
        message: String? = nil,
        progress: Double? = nil,
        printDuration: TimeInterval? = nil,
        estimatedTimeRemaining: TimeInterval? = nil,
        layer: LayerStatus? = nil,
        bed: TemperatureStatus? = nil,
        extruder: TemperatureStatus? = nil,
        feedRateMultiplier: Double? = nil,
        layerPatch: LayerStatusPatch? = nil,
        bedPatch: TemperatureStatusPatch? = nil,
        extruderPatch: TemperatureStatusPatch? = nil,
        clearedFields: PrinterStatusClearedFields = []
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
        self.layerPatch = layerPatch
        self.bedPatch = bedPatch
        self.extruderPatch = extruderPatch
        self.clearedFields = clearedFields
    }
}
