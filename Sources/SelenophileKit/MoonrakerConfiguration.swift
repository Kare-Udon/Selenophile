import Foundation

public struct MoonrakerConfiguration: Codable, Equatable, Sendable {
    public var serverURLString: String
    public var apiToken: String?
    public var cameraSnapshotURL: String?
    public var appLanguage: AppLanguage

    private enum CodingKeys: String, CodingKey {
        case serverURLString
        case apiToken
        case cameraSnapshotURL
        case appLanguage
    }

    public init(
        serverURLString: String,
        apiToken: String?,
        cameraSnapshotURL: String? = nil,
        appLanguage: AppLanguage = .system
    ) {
        self.serverURLString = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = apiToken?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.apiToken = trimmedToken?.isEmpty == true ? nil : trimmedToken
        let trimmedSnapshotURL = cameraSnapshotURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.cameraSnapshotURL = trimmedSnapshotURL?.isEmpty == true ? nil : trimmedSnapshotURL
        self.appLanguage = appLanguage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serverURLString = try container.decode(String.self, forKey: .serverURLString)
        let apiToken = try container.decodeIfPresent(String.self, forKey: .apiToken)
        let cameraSnapshotURL = try container.decodeIfPresent(String.self, forKey: .cameraSnapshotURL)
        let appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .system
        self.init(
            serverURLString: serverURLString,
            apiToken: apiToken,
            cameraSnapshotURL: cameraSnapshotURL,
            appLanguage: appLanguage
        )
    }

    public func validated() throws -> MoonrakerValidatedConfiguration {
        let trimmed = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MoonrakerConfigurationError.emptyURL
        }

        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased() else {
            throw MoonrakerConfigurationError.invalidURL
        }

        guard scheme == "http" || scheme == "https" else {
            throw MoonrakerConfigurationError.unsupportedScheme
        }

        guard url.host() != nil else {
            throw MoonrakerConfigurationError.invalidURL
        }

        var webSocketComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        webSocketComponents?.scheme = scheme == "https" ? "wss" : "ws"
        let basePath = url.path().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if basePath.isEmpty {
            webSocketComponents?.path = "/websocket"
        } else {
            webSocketComponents?.path = "/" + basePath + "/websocket"
        }
        webSocketComponents?.query = nil
        webSocketComponents?.fragment = nil

        guard let webSocketURL = webSocketComponents?.url else {
            throw MoonrakerConfigurationError.invalidURL
        }

        return MoonrakerValidatedConfiguration(
            httpURL: url,
            webSocketURL: webSocketURL,
            apiToken: apiToken,
            cameraSnapshotURL: cameraSnapshotURL
        )
    }
}

public struct MoonrakerValidatedConfiguration: Equatable, Sendable {
    public let httpURL: URL
    public let webSocketURL: URL
    public let apiToken: String?
    public let cameraSnapshotURL: String?

    public init(
        httpURL: URL,
        webSocketURL: URL,
        apiToken: String?,
        cameraSnapshotURL: String?
    ) {
        self.httpURL = httpURL
        self.webSocketURL = webSocketURL
        self.apiToken = apiToken
        self.cameraSnapshotURL = cameraSnapshotURL
    }
}

public enum MoonrakerConfigurationError: LocalizedError, Equatable {
    case emptyURL
    case invalidURL
    case unsupportedScheme

    public var errorDescription: String? {
        switch self {
        case .emptyURL:
            return "请输入 Moonraker 地址。"
        case .invalidURL:
            return "Moonraker 地址无效。"
        case .unsupportedScheme:
            return "Moonraker 地址只支持 http 或 https。"
        }
    }
}
