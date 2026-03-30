import Foundation
import Testing
@testable import SelenophileKit

@Test
func fetchSnapshotUsesConfiguredAbsoluteURL() async throws {
    try await URLProtocolStub.withExclusiveAccess {
        let session = makeURLSession()
        let client = MoonrakerCameraClient(session: session)
        let configuration = MoonrakerValidatedConfiguration(
            httpURL: URL(string: "http://printer.local:7125")!,
            webSocketURL: URL(string: "ws://printer.local:7125/websocket")!,
            apiToken: "secret",
            cameraSnapshotURL: "http://camera.local/snapshot.jpg"
        )
        let imageData = Data([0xFF, 0xD8, 0xFF])
        await URLProtocolStub.setResponses([
            .init(
                url: URL(string: "http://camera.local/snapshot.jpg")!,
                statusCode: 200,
                headers: ["Content-Type": "image/jpeg"],
                body: imageData
            ),
        ])

        let snapshot = try await client.fetchSnapshot(configuration: configuration)
        let requests = await URLProtocolStub.requests()

        #expect(snapshot == imageData)
        #expect(requests.count == 1)
        #expect(requests[0].url == URL(string: "http://camera.local/snapshot.jpg"))
        #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }
}

@Test
func fetchSnapshotResolvesRelativeURLAgainstMoonrakerHost() async throws {
    try await URLProtocolStub.withExclusiveAccess {
        let session = makeURLSession()
        let client = MoonrakerCameraClient(session: session)
        let configuration = MoonrakerValidatedConfiguration(
            httpURL: URL(string: "http://printer.local:7125")!,
            webSocketURL: URL(string: "ws://printer.local:7125/websocket")!,
            apiToken: nil,
            cameraSnapshotURL: "/webcam/?action=snapshot"
        )
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])
        await URLProtocolStub.setResponses([
            .init(
                url: URL(string: "http://printer.local/webcam/?action=snapshot")!,
                statusCode: 200,
                headers: ["Content-Type": "image/png"],
                body: imageData
            ),
        ])

        let snapshot = try await client.fetchSnapshot(configuration: configuration)
        let requests = await URLProtocolStub.requests()

        #expect(snapshot == imageData)
        #expect(requests[0].url == URL(string: "http://printer.local/webcam/?action=snapshot"))
    }
}

@Test
func fetchSnapshotFailsWhenURLIsMissing() async {
    let client = MoonrakerCameraClient(session: .shared)
    let configuration = MoonrakerValidatedConfiguration(
        httpURL: URL(string: "http://printer.local:7125")!,
        webSocketURL: URL(string: "ws://printer.local:7125/websocket")!,
        apiToken: nil,
        cameraSnapshotURL: nil
    )

    await #expect(throws: MoonrakerCameraError.noSnapshotURL) {
        try await client.fetchSnapshot(configuration: configuration)
    }
}

@Test
func fetchGCodeMetadataUsesMetadataEndpoint() async throws {
    try await URLProtocolStub.withExclusiveAccess {
        let session = makeURLSession()
        let client = MoonrakerClient(session: session)
        let configuration = MoonrakerValidatedConfiguration(
            httpURL: URL(string: "http://printer.local:7125")!,
            webSocketURL: URL(string: "ws://printer.local:7125/websocket")!,
            apiToken: "secret",
            cameraSnapshotURL: nil
        )
        await URLProtocolStub.setResponses([
            .init(
                url: URL(string: "http://printer.local:7125/server/files/metadata?filename=benchy.gcode")!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: Data(
                    #"{"result":{"estimated_time":1800,"thumbnails":[{"width":400,"height":300,"size":12345,"relative_path":".thumbs/benchy-400x300.png"}]}}"#
                    .utf8
                )
            ),
        ])

        let metadata = try await client.fetchGCodeMetadata(
            configuration: configuration,
            filename: "benchy.gcode"
        )
        let requests = await URLProtocolStub.requests()

        #expect(metadata.estimatedTime == 1800)
        #expect(metadata.thumbnails?.first?.relativePath == ".thumbs/benchy-400x300.png")
        #expect(requests.count == 1)
        #expect(requests[0].url == URL(string: "http://printer.local:7125/server/files/metadata?filename=benchy.gcode"))
        #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }
}

@Test
func rescanGCodeMetadataUsesPostMetascanEndpoint() async throws {
    try await URLProtocolStub.withExclusiveAccess {
        let session = makeURLSession()
        let client = MoonrakerClient(session: session)
        let configuration = MoonrakerValidatedConfiguration(
            httpURL: URL(string: "http://printer.local:7125")!,
            webSocketURL: URL(string: "ws://printer.local:7125/websocket")!,
            apiToken: "secret",
            cameraSnapshotURL: nil
        )
        await URLProtocolStub.setResponses([
            .init(
                url: URL(string: "http://printer.local:7125/server/files/metascan?filename=benchy.gcode")!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: Data(#"{"result":"ok"}"#.utf8)
            ),
        ])

        try await client.rescanGCodeMetadata(
            configuration: configuration,
            filename: "benchy.gcode"
        )
        let requests = await URLProtocolStub.requests()

        #expect(requests.count == 1)
        #expect(requests[0].httpMethod == "POST")
        #expect(requests[0].url == URL(string: "http://printer.local:7125/server/files/metascan?filename=benchy.gcode"))
        #expect(requests[0].value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    }
}

@Test
func fetchGCodeThumbnailUsesGcodeEndpoint() async throws {
    try await URLProtocolStub.withExclusiveAccess {
        let session = makeURLSession()
        let client = MoonrakerClient(session: session)
        let configuration = MoonrakerValidatedConfiguration(
            httpURL: URL(string: "http://printer.local:7125")!,
            webSocketURL: URL(string: "ws://printer.local:7125/websocket")!,
            apiToken: nil,
            cameraSnapshotURL: nil
        )
        let thumbnailData = Data([0x89, 0x50, 0x4E, 0x47])
        await URLProtocolStub.setResponses([
            .init(
                url: URL(string: "http://printer.local:7125/server/files/gcodes/prints/.thumbs/benchy-400x300.png")!,
                statusCode: 200,
                headers: ["Content-Type": "image/png"],
                body: thumbnailData
            ),
        ])

        let data = try await client.fetchGCodeThumbnail(
            configuration: configuration,
            filename: "prints/benchy.gcode",
            relativePath: ".thumbs/benchy-400x300.png"
        )
        let requests = await URLProtocolStub.requests()

        #expect(data == thumbnailData)
        #expect(requests.count == 1)
        #expect(requests[0].url == URL(string: "http://printer.local:7125/server/files/gcodes/prints/.thumbs/benchy-400x300.png"))
    }
}

private func makeURLSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    struct StubResponse: Sendable {
        let url: URL
        let statusCode: Int
        let headers: [String: String]
        let body: Data
    }

    private static let state = URLProtocolStubState()
    private static let testLock = URLProtocolStubLock()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Task {
            do {
                guard let url = request.url else { throw URLError(.badURL) }
                let response = try await Self.state.response(for: url, request: request)
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: response.statusCode,
                    httpVersion: nil,
                    headerFields: response.headers
                )!
                client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: response.body)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}

    static func setResponses(_ responses: [StubResponse]) async {
        await state.setResponses(responses)
    }

    static func requests() async -> [URLRequest] {
        await state.snapshotRequests()
    }

    static func withExclusiveAccess<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await testLock.run(operation)
    }
}

private actor URLProtocolStubState {
    private var responses: [URL: URLProtocolStub.StubResponse] = [:]
    private var recordedRequests: [URLRequest] = []

    func setResponses(_ responses: [URLProtocolStub.StubResponse]) {
        self.responses = Dictionary(uniqueKeysWithValues: responses.map { ($0.url, $0) })
        recordedRequests = []
    }

    func response(for url: URL, request: URLRequest) throws -> URLProtocolStub.StubResponse {
        recordedRequests.append(request)
        guard let response = responses[url] else { throw URLError(.resourceUnavailable) }
        return response
    }

    func snapshotRequests() -> [URLRequest] { recordedRequests }
}

private actor URLProtocolStubLock {
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func run<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        await acquire()
        defer { release() }
        return try await operation()
    }

    private func acquire() async {
        if !isLocked {
            isLocked = true
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func release() {
        if waiters.isEmpty {
            isLocked = false
            return
        }
        let continuation = waiters.removeFirst()
        continuation.resume()
    }
}
