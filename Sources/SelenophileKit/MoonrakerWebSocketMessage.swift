import Foundation

public struct MoonrakerWebSocketMessage: Decodable, Sendable {
    public let result: SubscriptionResult?
    public let method: String?
    public let params: StatusUpdateParams?
    public let error: RPCError?

    enum CodingKeys: String, CodingKey {
        case result
        case method
        case params
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decodeIfPresent(SubscriptionResult.self, forKey: .result)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        error = try container.decodeIfPresent(RPCError.self, forKey: .error)

        if method == "notify_status_update" {
            params = try container.decodeIfPresent(StatusUpdateParams.self, forKey: .params)
        } else {
            params = nil
        }
    }

    public var printerStatusSnapshot: PrinterStatus? {
        result?.status?.printerStatus
    }

    public var printerStatusDelta: PrinterStatusDelta? {
        guard method == "notify_status_update" else { return nil }
        return params?.status.printerStatusDelta
    }
}

public struct RPCError: Decodable, Sendable {
    public let code: Int
    public let message: String
}

public struct SubscriptionResult: Decodable, Sendable {
    public let eventtime: Double?
    public let status: MoonrakerStatusPayload?
}

public struct StatusUpdateParams: Decodable, Sendable {
    public let status: MoonrakerStatusPayload
    public let eventtime: Double?

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        status = try container.decode(MoonrakerStatusPayload.self)
        eventtime = try container.decodeIfPresent(Double.self)
    }
}

public struct MoonrakerStatusPayload: Decodable, Sendable {
    public let printStats: PrintStatsPayload?
    public let displayStatus: DisplayStatusPayload?
    public let virtualSDCard: VirtualSDCardPayload?
    public let extruder: HeaterPayload?
    public let heaterBed: HeaterPayload?
    public let gcodeMove: GCodeMovePayload?

    enum CodingKeys: String, CodingKey {
        case printStats = "print_stats"
        case displayStatus = "display_status"
        case virtualSDCard = "virtual_sdcard"
        case extruder
        case heaterBed = "heater_bed"
        case gcodeMove = "gcode_move"
    }

    public var printerStatus: PrinterStatus {
        PrinterStatus(
            state: printStats?.state ?? .unknown,
            filename: printStats?.filename,
            message: preferredMessage,
            progress: preferredProgress,
            printDuration: printStats?.printDuration,
            estimatedTimeRemaining: estimatedRemaining,
            layer: printStats?.layerStatus,
            bed: heaterBed?.temperatureStatus,
            extruder: extruder?.temperatureStatus,
            feedRateMultiplier: gcodeMove?.speedFactor
        )
    }

    public var printerStatusDelta: PrinterStatusDelta {
        PrinterStatusDelta(
            state: printStats?.state,
            filename: printStats?.filename,
            message: preferredMessage,
            progress: preferredProgress,
            printDuration: printStats?.printDuration,
            estimatedTimeRemaining: estimatedRemaining,
            layer: printStats?.layerStatus,
            bed: heaterBed?.temperatureStatus,
            extruder: extruder?.temperatureStatus,
            feedRateMultiplier: gcodeMove?.speedFactor
        )
    }

    private var preferredProgress: Double? {
        displayStatus?.progress ?? virtualSDCard?.progress
    }

    private var preferredMessage: String? {
        if let displayMessage = displayStatus?.message?.nonEmpty {
            return displayMessage
        }
        return printStats?.message?.nonEmpty
    }

    private var estimatedRemaining: TimeInterval? {
        guard let progress = preferredProgress,
              let printDuration = printStats?.printDuration,
              progress > 0,
              progress < 1
        else {
            return nil
        }
        return printDuration * (1 - progress) / progress
    }
}

public struct PrintStatsPayload: Decodable, Sendable {
    public let stateString: String?
    public let filename: String?
    public let message: String?
    public let printDuration: Double?
    public let info: PrintStatsInfoPayload?

    enum CodingKeys: String, CodingKey {
        case stateString = "state"
        case filename
        case message
        case printDuration = "print_duration"
        case info
    }

    public var state: PrinterState? {
        guard let stateString else { return nil }
        return PrinterState(rawValue: stateString)
    }

    public var layerStatus: LayerStatus? {
        guard let current = info?.currentLayer else { return nil }
        return LayerStatus(current: current, total: info?.totalLayer)
    }
}

public struct PrintStatsInfoPayload: Decodable, Sendable {
    public let currentLayer: Int?
    public let totalLayer: Int?

    enum CodingKeys: String, CodingKey {
        case currentLayer = "current_layer"
        case totalLayer = "total_layer"
    }
}

public struct DisplayStatusPayload: Decodable, Sendable {
    public let progress: Double?
    public let message: String?
}

public struct VirtualSDCardPayload: Decodable, Sendable {
    public let progress: Double?
}

public struct HeaterPayload: Decodable, Sendable {
    public let temperature: Double?
    public let target: Double?

    public var temperatureStatus: TemperatureStatus? {
        guard let temperature, let target else { return nil }
        return TemperatureStatus(actual: temperature, target: target)
    }
}

public struct GCodeMovePayload: Decodable, Sendable {
    public let speedFactor: Double?

    enum CodingKeys: String, CodingKey {
        case speedFactor = "speed_factor"
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
