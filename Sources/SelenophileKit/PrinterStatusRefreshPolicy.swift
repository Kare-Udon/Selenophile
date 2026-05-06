import Foundation

public enum PrinterStatusRefreshPolicy: Equatable, Hashable, Sendable {
    case realtime
    case seconds(Int)

    public static let supportedSelections: [PrinterStatusRefreshPolicy] = [
        .realtime,
        .seconds(1),
        .seconds(2),
        .seconds(3),
        .seconds(5),
        .seconds(7),
        .seconds(10),
    ]

    public var rawValue: String {
        switch self {
        case .realtime:
            return "realtime"
        case .seconds(let seconds):
            return "\(seconds)s"
        }
    }

    public var intervalSeconds: Int? {
        switch self {
        case .realtime:
            return nil
        case .seconds(let seconds):
            return seconds
        }
    }

    public init(rawValue: String) {
        if rawValue == "realtime" {
            self = .realtime
            return
        }

        let normalized = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "s"))
        guard let seconds = Int(normalized),
              Self.supportedSelections.contains(.seconds(seconds))
        else {
            self = .realtime
            return
        }
        self = .seconds(seconds)
    }
}

public protocol PrinterStatusRefreshPolicyPersisting {
    func load() -> PrinterStatusRefreshPolicy
    func save(_ policy: PrinterStatusRefreshPolicy)
}

public final class UserDefaultsPrinterStatusRefreshPolicyStore: PrinterStatusRefreshPolicyPersisting {
    private let defaults: UserDefaults
    private let key = "printer.status.refreshPolicy"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> PrinterStatusRefreshPolicy {
        guard let rawValue = defaults.string(forKey: key) else {
            return .realtime
        }
        return PrinterStatusRefreshPolicy(rawValue: rawValue)
    }

    public func save(_ policy: PrinterStatusRefreshPolicy) {
        defaults.set(policy.rawValue, forKey: key)
    }
}
