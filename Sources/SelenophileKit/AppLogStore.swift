import Foundation
import Observation

public enum AppLogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error

    fileprivate var severity: Int {
        switch self {
        case .debug:
            return 0
        case .info:
            return 1
        case .warning:
            return 2
        case .error:
            return 3
        }
    }
}

extension AppLogLevel: Comparable {
    public static func < (lhs: AppLogLevel, rhs: AppLogLevel) -> Bool {
        lhs.severity < rhs.severity
    }
}

public struct AppLogEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: AppLogLevel
    public let source: String
    public let message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        level: AppLogLevel,
        source: String,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.source = source
        self.message = message
    }
}

@MainActor
@Observable
public final class AppLogStore {
    public private(set) var entries: [AppLogEntry] = []

    private let maxEntries: Int
    private let dateProvider: @Sendable () -> Date

    public init(
        maxEntries: Int = 300,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.maxEntries = max(1, maxEntries)
        self.dateProvider = dateProvider
    }

    public func log(_ level: AppLogLevel, source: String, message: String) {
        let source = Self.sanitizedEnglishLogText(source)
        let message = Self.sanitizedEnglishLogText(message)
        let entry = AppLogEntry(
            timestamp: dateProvider(),
            level: level,
            source: source,
            message: message
        )

        entries.insert(entry, at: 0)

        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    public static func sanitizedEnglishLogText(_ text: String) -> String {
        var sanitized = ""
        var isOmittingNonASCII = false

        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x20...0x7E:
                sanitized.unicodeScalars.append(scalar)
                isOmittingNonASCII = false
            case 0x09, 0x0A, 0x0D:
                sanitized.append(" ")
                isOmittingNonASCII = false
            default:
                if !isOmittingNonASCII {
                    sanitized.append("[non-ASCII text omitted]")
                    isOmittingNonASCII = true
                }
            }
        }

        return sanitized
    }

    public static func diagnosticDescription(for error: any Error) -> String {
        let nsError = error as NSError
        let domain = sanitizedEnglishLogText(nsError.domain)
        return "\(String(reflecting: type(of: error))) (domain: \(domain), code: \(nsError.code))"
    }

    public func clear() {
        entries.removeAll()
    }

    public func visibleEntries(minimumLevel: AppLogLevel) -> [AppLogEntry] {
        entries.filter { $0.level >= minimumLevel }
    }

    public func exportText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return entries.map { entry in
            "\(formatter.string(from: entry.timestamp)) [\(entry.level.rawValue)] [\(entry.source)] \(entry.message)"
        }
        .joined(separator: "\n")
    }
}
