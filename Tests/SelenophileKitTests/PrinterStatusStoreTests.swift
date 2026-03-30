import Foundation
import Testing
@testable import SelenophileKit

@MainActor
@Test
func connectingIgnoresIntentionalDisconnectPlaceholder() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.connectionState = .connecting
    store.handle(event: .disconnected("已断开连接"))

    #expect(store.connectionState == .connecting)
    #expect(store.lastErrorMessage == nil)
}

@MainActor
@Test
func stopsAutoRetryAfterMaximumFailures() async {
    let client = ScriptedMoonrakerClient(eventsPerConnect: [
        [.failed("连接超时")],
        [.failed("连接超时")],
        [.failed("连接超时")],
        [.failed("连接超时")],
    ])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(maxAttempts: 3, delay: { _ in .zero }),
        sleep: { _ in }
    )

    store.start()
    try? await Task.sleep(for: .milliseconds(100))

    #expect(await client.connectCallCount() == 3)
    #expect(store.connectionState == .failed)
    #expect(store.isWaitingForManualReconnect)
    #expect(store.retryAttemptCount == 3)
}

@MainActor
@Test
func manualReconnectResetsRetryBudget() async {
    let client = ScriptedMoonrakerClient(eventsPerConnect: [
        [.failed("连接超时")],
        [.failed("连接超时")],
        [.failed("连接超时")],
        [.connected],
    ])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(maxAttempts: 3, delay: { _ in .zero }),
        sleep: { _ in }
    )

    store.start()
    try? await Task.sleep(for: .milliseconds(100))
    #expect(store.isWaitingForManualReconnect)

    store.reconnectNow()
    try? await Task.sleep(for: .milliseconds(100))

    #expect(await client.connectCallCount() == 4)
    #expect(store.connectionState == .connected)
    #expect(!store.isWaitingForManualReconnect)
    #expect(store.retryAttemptCount == 0)
}

@MainActor
@Test
func userFacingStatusAndErrorAreTranslatedAfterRetryExhaustion() async {
    let client = ScriptedMoonrakerClient(eventsPerConnect: [
        [.failed("The data couldn’t be read because it isn’t in the correct format.")]
    ])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(maxAttempts: 1, delay: { _ in .zero }),
        sleep: { _ in }
    )

    store.start()
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.connectionBadgeLabel == "需要处理")
    #expect(store.connectionStatusSummary == "自动重试已停止，请手动重连")
    #expect(store.displayErrorMessage == "Moonraker 返回的数据格式与当前解析规则不一致。")
}

@MainActor
@Test
func fetchCameraSnapshotStoresImageData() async throws {
    let snapshot = Data([0x01, 0x02, 0x03])
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        cameraClient: StubMoonrakerCameraClient(snapshotResult: .success(snapshot)),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: "token",
                cameraSnapshotURL: "http://camera.local/snapshot.jpg"
            )
        )
    )

    let success = await store.fetchCameraSnapshot()

    #expect(success)
    #expect(store.cameraSnapshotData == snapshot)
    #expect(store.cameraSnapshotErrorMessage == nil)
    #expect(!store.isFetchingCameraSnapshot)
}

@MainActor
@Test
func fetchCameraSnapshotReportsFailure() async throws {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        cameraClient: StubMoonrakerCameraClient(snapshotResult: .failure(MoonrakerCameraError.noSnapshotURL)),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil, cameraSnapshotURL: nil)
        )
    )

    let success = await store.fetchCameraSnapshot()

    #expect(!success)
    #expect(store.cameraSnapshotData == nil)
    #expect(store.cameraSnapshotErrorMessage == MoonrakerCameraError.noSnapshotURL.localizedDescription)
    #expect(!store.isFetchingCameraSnapshot)
}

@MainActor
@Test
func slicerMetadataOverridesFileRemainingTime() async {
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[]],
        metadataSequencesByFilename: [
            "benchy.gcode": [
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: [
                        MoonrakerThumbnailInfo(width: 400, height: 300, size: 12345, relativePath: ".thumbs/benchy-400x300.png")
                    ]
                )
            ]
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.handle(
        event: .printerStatus(
            PrinterStatus(
                state: .printing,
                filename: "benchy.gcode",
                progress: 0.4,
                printDuration: 600
            )
        )
    )

    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.printerStatus.slicerEstimatedPrintTime == 1800)
}

@MainActor
@Test
func thumbnailMetadataLoadsCurrentPrintThumbnail() async {
    let thumbnailData = Data([0x89, 0x50, 0x4E, 0x47])
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[]],
        metadataSequencesByFilename: [
            "benchy.gcode": [
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: [
                        MoonrakerThumbnailInfo(width: 400, height: 300, size: 12345, relativePath: ".thumbs/benchy-400x300.png")
                    ]
                )
            ]
        ],
        thumbnailDataByPath: [
            ".thumbs/benchy-400x300.png": thumbnailData
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.handle(
        event: .printerStatus(
            PrinterStatus(
                state: .printing,
                filename: "benchy.gcode",
                progress: 0.4,
                printDuration: 600
            )
        )
    )

    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == thumbnailData)
}

@MainActor
@Test
func thumbnailMetadataRescansWhenInitialMetadataHasNoThumbnail() async {
    let thumbnailData = Data([0x89, 0x50, 0x4E, 0x47])
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[]],
        metadataSequencesByFilename: [
            "benchy.gcode": [
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: nil
                ),
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: [
                        MoonrakerThumbnailInfo(width: 400, height: 300, size: 12345, relativePath: ".thumbs/benchy-400x300.png")
                    ]
                )
            ]
        ],
        thumbnailDataByPath: [
            ".thumbs/benchy-400x300.png": thumbnailData
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.handle(
        event: .printerStatus(
            PrinterStatus(
                state: .printing,
                filename: "benchy.gcode",
                progress: 0.4,
                printDuration: 600
            )
        )
    )

    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == thumbnailData)
    #expect(await client.rescanCallCount() == 1)
}

@MainActor
@Test
func thumbnailMetadataRetriesOnSameFilenameUntilThumbnailAppears() async {
    let thumbnailData = Data([0x89, 0x50, 0x4E, 0x47])
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[]],
        metadataSequencesByFilename: [
            "benchy.gcode": [
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: nil
                ),
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: nil
                ),
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: [
                        MoonrakerThumbnailInfo(width: 400, height: 300, size: 12345, relativePath: ".thumbs/benchy-400x300.png")
                    ]
                )
            ]
        ],
        thumbnailDataByPath: [
            ".thumbs/benchy-400x300.png": thumbnailData
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    let status = PrinterStatus(
        state: .printing,
        filename: "benchy.gcode",
        progress: 0.4,
        printDuration: 600
    )

    store.handle(event: .printerStatus(status))
    try? await Task.sleep(for: .milliseconds(100))
    #expect(store.currentPrintThumbnailData == nil)

    store.handle(event: .printerStatus(status))
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == thumbnailData)
    #expect(await client.rescanCallCount() == 1)
}

@MainActor
@Test
func thumbnailMetadataStopsAfterMaxRetriesAndManualRetryResumes() async {
    let thumbnailData = Data([0x89, 0x50, 0x4E, 0x47])
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[]],
        metadataSequencesByFilename: [
            "benchy.gcode": [
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: nil
                ),
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: nil
                ),
                MoonrakerFileMetadata(
                    filename: "benchy.gcode",
                    estimatedTime: 1800,
                    thumbnails: [
                        MoonrakerThumbnailInfo(width: 400, height: 300, size: 12345, relativePath: ".thumbs/benchy-400x300.png")
                    ]
                )
            ]
        ],
        thumbnailDataByPath: [
            ".thumbs/benchy-400x300.png": thumbnailData
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        currentPrintThumbnailRetryLimit: 1
    )

    let status = PrinterStatus(
        state: .printing,
        filename: "benchy.gcode",
        progress: 0.4,
        printDuration: 600
    )

    store.handle(event: .printerStatus(status))
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == nil)
    #expect(store.isWaitingForManualCurrentPrintThumbnailRetry)

    store.handle(event: .printerStatus(status))
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == nil)
    #expect(await client.rescanCallCount() == 1)

    store.retryCurrentPrintThumbnail()
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == thumbnailData)
    #expect(!store.isWaitingForManualCurrentPrintThumbnailRetry)
}

@MainActor
@Test
func saveConfigurationPersistsCameraSnapshotURL() async throws {
    let persistence = RecordingMoonrakerConfigurationStore()
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        cameraClient: StubMoonrakerCameraClient(snapshotResult: .failure(MoonrakerCameraError.noSnapshotURL)),
        persistence: persistence
    )

    let success = await store.saveConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "token",
        cameraSnapshotURL: "http://camera.local/snapshot.jpg"
    )

    #expect(success)
    let saved = persistence.savedConfiguration()
    #expect(saved?.cameraSnapshotURL == "http://camera.local/snapshot.jpg")
    #expect(store.cameraSnapshotURL == "http://camera.local/snapshot.jpg")
}

@MainActor
@Test
func saveConfigurationPersistsSelectedAppLanguage() async throws {
    let persistence = RecordingMoonrakerConfigurationStore()
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: persistence
    )

    let success = await store.saveConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "token",
        cameraSnapshotURL: nil,
        appLanguage: .traditionalChinese
    )

    #expect(success)
    #expect(persistence.savedConfiguration()?.appLanguage == .traditionalChinese)
    #expect(store.configuration?.appLanguage == .traditionalChinese)
}

@MainActor
@Test
func saveConfigurationAndConnectionFailuresAreLogged() async {
    let logStore = AppLogStore(maxEntries: 20, dateProvider: { Date(timeIntervalSince1970: 0) })
    let client = ScriptedMoonrakerClient(eventsPerConnect: [[.failed("连接超时")]])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(),
        retryPolicy: MoonrakerRetryPolicy(maxAttempts: 1, delay: { _ in .zero }),
        sleep: { _ in },
        logStore: logStore
    )

    let success = await store.saveConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: nil
    )
    #expect(success)

    try? await Task.sleep(for: .milliseconds(100))

    #expect(logStore.entries.contains(where: { $0.message.contains("配置已保存") }))
    #expect(logStore.entries.contains(where: { $0.message.contains("开始连接 Moonraker") }))
    #expect(logStore.entries.contains(where: { $0.message.contains("连接失败") }))
}

private actor NoopMoonrakerClient: MoonrakerClientProtocol {
    func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async {}

    func disconnect() async {}

    func rescanGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws {}

    func fetchGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws -> MoonrakerFileMetadata {
        MoonrakerFileMetadata(filename: filename, estimatedTime: nil, thumbnails: nil)
    }

    func fetchGCodeThumbnail(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        relativePath: String
    ) async throws -> Data {
        Data()
    }
}

private actor StubMoonrakerCameraClient: MoonrakerCameraClientProtocol {
    let snapshotResult: Result<Data, Error>

    init(snapshotResult: Result<Data, Error>) {
        self.snapshotResult = snapshotResult
    }

    func fetchSnapshot(configuration: MoonrakerValidatedConfiguration) async throws -> Data {
        try snapshotResult.get()
    }
}

private struct InMemoryMoonrakerConfigurationStore: MoonrakerConfigurationPersisting {
    var configuration: MoonrakerConfiguration?

    func load() -> MoonrakerConfiguration? {
        configuration
    }

    func save(_ configuration: MoonrakerConfiguration) {}

    func clear() {}
}

private final class RecordingMoonrakerConfigurationStore: MoonrakerConfigurationPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var configuration: MoonrakerConfiguration?

    func load() -> MoonrakerConfiguration? {
        lock.withLock { configuration }
    }

    func save(_ configuration: MoonrakerConfiguration) {
        lock.withLock {
            self.configuration = configuration
        }
    }

    func clear() {
        lock.withLock {
            configuration = nil
        }
    }

    func savedConfiguration() -> MoonrakerConfiguration? {
        lock.withLock { configuration }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

private actor ScriptedMoonrakerClient: MoonrakerClientProtocol {
    private let eventsPerConnect: [[MoonrakerClientEvent]]
    private let metadataSequencesByFilename: [String: [MoonrakerFileMetadata]]
    private let thumbnailDataByPath: [String: Data]
    private var connectCalls = 0
    private var rescanCalls = 0
    private var metadataFetchCounts: [String: Int] = [:]

    init(
        eventsPerConnect: [[MoonrakerClientEvent]],
        metadataSequencesByFilename: [String: [MoonrakerFileMetadata]] = [:],
        thumbnailDataByPath: [String: Data] = [:]
    ) {
        self.eventsPerConnect = eventsPerConnect
        self.metadataSequencesByFilename = metadataSequencesByFilename
        self.thumbnailDataByPath = thumbnailDataByPath
    }

    func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async {
        let index = connectCalls
        connectCalls += 1
        let events = index < eventsPerConnect.count ? eventsPerConnect[index] : []
        for event in events {
            onEvent(event)
        }
    }

    func disconnect() async {}

    func rescanGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws {
        rescanCalls += 1
    }

    func fetchGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws -> MoonrakerFileMetadata {
        let fetchCount = metadataFetchCounts[filename, default: 0]
        metadataFetchCounts[filename] = fetchCount + 1
        let metadataSequence = metadataSequencesByFilename[filename] ?? []
        if metadataSequence.isEmpty {
            return MoonrakerFileMetadata(filename: filename, estimatedTime: nil, thumbnails: nil)
        }
        return metadataSequence[min(fetchCount, metadataSequence.count - 1)]
    }

    func fetchGCodeThumbnail(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        relativePath: String
    ) async throws -> Data {
        thumbnailDataByPath[relativePath] ?? Data()
    }

    func connectCallCount() -> Int {
        connectCalls
    }

    func rescanCallCount() -> Int {
        rescanCalls
    }
}
