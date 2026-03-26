import Foundation

public enum MoonrakerClientEvent: Sendable {
    case connected
    case printerStatus(PrinterStatus)
    case printerStatusDelta(PrinterStatusDelta)
    case disconnected(String?)
    case failed(String)
}

public protocol MoonrakerClientProtocol: Sendable {
    func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async
    func disconnect() async
    func rescanGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws
    func fetchGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws -> MoonrakerFileMetadata
    func fetchGCodeThumbnail(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        relativePath: String
    ) async throws -> Data
}

public struct MoonrakerFileMetadata: Decodable, Sendable {
    public let filename: String?
    public let estimatedTime: TimeInterval?
    public let thumbnails: [MoonrakerThumbnailInfo]?

    enum CodingKeys: String, CodingKey {
        case filename
        case estimatedTime = "estimated_time"
        case thumbnails
    }
}

public struct MoonrakerThumbnailInfo: Decodable, Sendable {
    public let width: Int?
    public let height: Int?
    public let size: Int?
    public let relativePath: String

    enum CodingKeys: String, CodingKey {
        case width
        case height
        case size
        case relativePath = "relative_path"
    }
}

public actor MoonrakerClient: MoonrakerClientProtocol {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private var webSocketTask: URLSessionWebSocketTask?
    private var eventHandler: (@Sendable (MoonrakerClientEvent) -> Void)?
    private var requestID: Int = 1

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async {
        cleanupCurrentTask()
        eventHandler = onEvent

        let task = session.webSocketTask(with: configuration.webSocketURL)
        webSocketTask = task
        task.resume()

        do {
            try await sendIdentify(using: configuration)
            try await sendSubscribe()
            await emit(.connected)
            await receiveLoop(for: task)
        } catch {
            await emit(.failed(error.localizedDescription))
            cleanupCurrentTask()
        }
    }

    public func disconnect() async {
        cleanupCurrentTask(notifyDisconnection: true, reason: "已断开连接")
    }

    public func rescanGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws {
        let metascanURL = try metascanURL(configuration: configuration, filename: filename)
        var request = URLRequest(url: metascanURL)
        if let apiToken = configuration.apiToken {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
    }

    public func fetchGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws -> MoonrakerFileMetadata {
        let metadataURL = try metadataURL(configuration: configuration, filename: filename)
        var request = URLRequest(url: metadataURL)
        if let apiToken = configuration.apiToken {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(MoonrakerFileMetadata.self, from: data)
    }

    public func fetchGCodeThumbnail(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        relativePath: String
    ) async throws -> Data {
        let thumbnailURL = try gcodeFileURL(
            configuration: configuration,
            filename: filename,
            relativePath: relativePath
        )
        var request = URLRequest(url: thumbnailURL)
        if let apiToken = configuration.apiToken {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func cleanupCurrentTask(notifyDisconnection: Bool = false, reason: String? = nil) {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        if notifyDisconnection, let reason {
            Task { await emit(.disconnected(reason)) }
        }
    }

    private func receiveLoop(for task: URLSessionWebSocketTask) async {
        while webSocketTask === task {
            do {
                let message = try await task.receive()
                switch message {
                case .string(let text):
                    try await handleIncoming(text: text)
                case .data(let data):
                    try await handleIncoming(data: data)
                @unknown default:
                    break
                }
            } catch {
                if webSocketTask === task {
                    await emit(.disconnected(error.localizedDescription))
                    cleanupCurrentTask()
                }
                break
            }
        }
    }

    private func handleIncoming(text: String) async throws {
        guard let data = text.data(using: .utf8) else { return }
        try await handleIncoming(data: data)
    }

    private func handleIncoming(data: Data) async throws {
        let message = try decoder.decode(MoonrakerWebSocketMessage.self, from: data)
        if let error = message.error {
            await emit(.failed(error.message))
            return
        }
        if let snapshot = message.printerStatusSnapshot {
            await emit(.printerStatus(snapshot))
        }
        if let delta = message.printerStatusDelta {
            await emit(.printerStatusDelta(delta))
        }
    }

    private func sendIdentify(using configuration: MoonrakerValidatedConfiguration) async throws {
        let request = MoonrakerRequest.identify(
            id: nextRequestID(),
            clientName: AppConfig.appName,
            version: "0.1.0",
            url: AppConfig.projectURL,
            accessToken: configuration.apiToken
        )
        try await send(request)
    }

    private func sendSubscribe() async throws {
        let request = MoonrakerRequest.subscribe(
            id: nextRequestID(),
            objects: MoonrakerSubscriptionObjects.default
        )
        try await send(request)
    }

    private func send(_ request: MoonrakerRequest) async throws {
        let payload = try encoder.encode(request)
        guard let text = String(data: payload, encoding: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        try await webSocketTask?.send(.string(text))
    }

    private func metadataURL(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) throws -> URL {
        let baseURL = configuration.httpURL
            .appendingPathComponent("server")
            .appendingPathComponent("files")
            .appendingPathComponent("metadata")
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "filename", value: filename)
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func metascanURL(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) throws -> URL {
        let baseURL = configuration.httpURL
            .appendingPathComponent("server")
            .appendingPathComponent("files")
            .appendingPathComponent("metascan")
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "filename", value: filename)
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    private func gcodeFileURL(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        relativePath: String
    ) throws -> URL {
        var url = configuration.httpURL
            .appendingPathComponent("server")
            .appendingPathComponent("files")
            .appendingPathComponent("gcodes")

        let filenameComponents = filename.split(separator: "/").map(String.init)
        if filenameComponents.count > 1 {
            for component in filenameComponents.dropLast() {
                url.appendPathComponent(component)
            }
        }

        for component in relativePath.split(separator: "/").map(String.init) {
            url.appendPathComponent(component)
        }
        return url
    }

    private func nextRequestID() -> Int {
        defer { requestID += 1 }
        return requestID
    }

    private func emit(_ event: MoonrakerClientEvent) async {
        eventHandler?(event)
    }
}

private enum MoonrakerSubscriptionObjects {
    static let `default`: [String: [String]] = [
        "print_stats": ["state", "filename", "message", "print_duration", "info"],
        "display_status": ["progress", "message"],
        "virtual_sdcard": ["progress"],
        "extruder": ["temperature", "target"],
        "heater_bed": ["temperature", "target"],
        "gcode_move": ["speed_factor"],
    ]
}

private struct MoonrakerRequest: Encodable {
    let jsonrpc = "2.0"
    let method: String
    let params: Parameters
    let id: Int

    struct Parameters: Encodable {
        let raw: EncodableValue

        func encode(to encoder: Encoder) throws {
            try raw.encode(to: encoder)
        }
    }

    static func identify(
        id: Int,
        clientName: String,
        version: String,
        url: String,
        accessToken: String?
    ) -> MoonrakerRequest {
        var payload: [String: Any] = [
            "client_name": clientName,
            "version": version,
            "type": "desktop",
            "url": url,
        ]
        if let accessToken, !accessToken.isEmpty {
            payload["access_token"] = accessToken
        }
        return MoonrakerRequest(
            method: "server.connection.identify",
            params: Parameters(
                raw: EncodableValue(payload)
            ),
            id: id
        )
    }

    static func subscribe(id: Int, objects: [String: [String]]) -> MoonrakerRequest {
        MoonrakerRequest(
            method: "printer.objects.subscribe",
            params: Parameters(raw: EncodableValue(["objects": objects])),
            id: id
        )
    }
}

private struct EncodableValue: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(EncodableValue.init))
        case let array as [Any]:
            try container.encode(array.map(EncodableValue.init))
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported value")
            )
        }
    }
}
