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
    store.handle(event: .disconnected("Disconnected"))

    #expect(store.connectionState == .connecting)
    #expect(store.lastErrorMessage == nil)
}

@MainActor
@Test
func automaticReconnectKeepsRetryingWithCappedBackoff() async {
    let sleeper = ControlledSleeper()
    let client = ScriptedMoonrakerClient(eventsPerConnect: [
        [.failed("Connection timed out")],
        [.failed("Connection timed out")],
        [.failed("Connection timed out")],
        [.failed("Connection timed out")],
    ])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(delays: [.seconds(30), .seconds(60), .seconds(300)]),
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )

    store.start()
    await sleeper.waitForPendingSleepCount(1)
    #expect(await client.connectCallCount() == 1)
    #expect(await sleeper.pendingDurations() == [.seconds(30)])

    await sleeper.resumeAll()
    await sleeper.waitForPendingSleepCount(1)
    #expect(await client.connectCallCount() == 2)
    #expect(await sleeper.pendingDurations() == [.seconds(60)])

    await sleeper.resumeAll()
    await sleeper.waitForPendingSleepCount(1)
    #expect(await client.connectCallCount() == 3)
    #expect(await sleeper.pendingDurations() == [.seconds(300)])

    await sleeper.resumeAll()
    await sleeper.waitForPendingSleepCount(1)
    #expect(await client.connectCallCount() == 4)
    #expect(await sleeper.pendingDurations() == [.seconds(300)])
    #expect(!store.isWaitingForManualReconnect)
}

@MainActor
@Test
func manualReconnectResetsRetryBudget() async {
    let sleeper = ControlledSleeper()
    let client = ScriptedMoonrakerClient(eventsPerConnect: [
        [.failed("Connection timed out")],
        [.connected],
    ])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(delays: [.seconds(30), .seconds(60), .seconds(300)]),
        statusSnapshotRefreshInterval: nil,
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )

    store.start()
    await sleeper.waitForPendingSleepCount(1)
    #expect(store.retryAttemptCount == 1)

    store.reconnectNow()
    try? await Task.sleep(for: .milliseconds(100))

    #expect(await client.connectCallCount() == 2)
    #expect(store.connectionState == .connected)
    #expect(!store.isWaitingForManualReconnect)
    #expect(store.retryAttemptCount == 0)
}

@MainActor
@Test
func userFacingStatusAndErrorAreTranslatedWhileAutomaticRetryContinues() async {
    let sleeper = ControlledSleeper()
    let client = ScriptedMoonrakerClient(eventsPerConnect: [
        [.failed("The data couldn’t be read because it isn’t in the correct format.")]
    ])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(delays: [.seconds(30)]),
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )

    store.start()
    await sleeper.waitForPendingSleepCount(1)

    #expect(store.connectionBadgeLabel(language: .simplifiedChinese) == "重试中")
    #expect(store.connectionStatusSummary(language: .simplifiedChinese).contains("30 秒后重试"))
    #expect(store.displayErrorMessage(language: .simplifiedChinese) == "Moonraker 返回的数据格式与当前解析规则不一致。")
    #expect(store.connectionBadgeLabel(language: .japanese) == "再試行中")
    #expect(store.connectionStatusSummary(language: .japanese).contains("30 秒後に再試行"))
    #expect(store.displayErrorMessage(language: .japanese) == "Moonraker から返されたデータが現在の解析ルールと一致しません。")
}

@MainActor
@Test
func displayErrorLocalizesCommonURLSessionFailures() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: nil,
                appLanguage: .japanese
            )
        )
    )

    store.lastErrorMessage = "A server with the specified hostname could not be found."

    #expect(store.displayErrorMessage(language: .japanese) == "Moonraker に接続できません。アドレス、ポート、ネットワークを確認してください。")
    #expect(store.displayErrorMessage(language: .simplifiedChinese) == "无法连接到 Moonraker，请检查地址、端口或网络。")
}

@MainActor
@Test
func realtimeStatusRefreshPublishesEveryStatusUpdate() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: nil,
                appLanguage: .simplifiedChinese
            )
        ),
        statusRefreshPolicy: .realtime
    )
    store.connectionState = .connected
    var snapshots: [WidgetSnapshot] = []
    store.onWidgetSnapshotChange = { snapshots.append($0) }

    store.handle(event: .printerStatus(PrinterStatus(state: .printing, progress: 0.1)))
    store.handle(event: .printerStatusDelta(PrinterStatusDelta(progress: 0.2)))

    #expect(store.printerStatus.progress == 0.2)
    #expect(snapshots.count == 2)
    #expect(snapshots.last?.progressLabel == "20%")
}

@MainActor
@Test
func connectedStoreFetchesFullStatusSnapshotImmediately() async {
    let sleeper = ControlledSleeper()
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[.connected]],
        statusSnapshots: [
            PrinterStatus(state: .printing, filename: "benchy.gcode", progress: 0.12)
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        statusSnapshotRefreshInterval: .seconds(60),
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )

    store.start()
    await sleeper.waitForPendingSleepCount(1)

    #expect(await client.fetchCurrentStatusCallCount() == 1)
    #expect(store.printerStatus.state == .printing)
    #expect(store.printerStatus.filename == "benchy.gcode")
    #expect(store.printerStatus.progress == 0.12)
}

@MainActor
@Test
func connectedStorePeriodicallyFetchesFullStatusSnapshot() async {
    let sleeper = ControlledSleeper()
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[.connected]],
        statusSnapshots: [
            PrinterStatus(state: .standby),
            PrinterStatus(state: .printing, filename: "benchy.gcode", progress: 0.25)
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        statusSnapshotRefreshInterval: .seconds(60),
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )

    store.start()
    await sleeper.waitForPendingSleepCount(1)
    #expect(await client.fetchCurrentStatusCallCount() == 1)
    #expect(await sleeper.pendingDurations() == [.seconds(60)])
    #expect(store.printerStatus.state == .standby)

    await sleeper.resumeAll()
    await sleeper.waitForPendingSleepCount(1)

    #expect(await client.fetchCurrentStatusCallCount() == 2)
    #expect(await sleeper.pendingDurations() == [.seconds(60)])
    #expect(store.printerStatus.state == .printing)
    #expect(store.printerStatus.filename == "benchy.gcode")
    #expect(store.printerStatus.progress == 0.25)
}

@MainActor
@Test
func disconnectedStoreDoesNotRunPeriodicFullStatusRefresh() async {
    let sleeper = ControlledSleeper()
    let client = ScriptedMoonrakerClient(
        eventsPerConnect: [[.connected]],
        statusSnapshots: [
            PrinterStatus(state: .printing, filename: "benchy.gcode", progress: 0.25)
        ]
    )
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(delays: [.seconds(30)]),
        statusSnapshotRefreshInterval: .seconds(60),
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )

    store.start()
    await sleeper.waitForPendingSleepCount(1)

    #expect(await client.fetchCurrentStatusCallCount() == 1)
    store.handle(event: .disconnected("Network lost"))
    await sleeper.resumeFirst(matching: .seconds(60))

    #expect(await client.fetchCurrentStatusCallCount() == 1)
    #expect(store.connectionState == .disconnected)
    #expect(await sleeper.pendingDurations() == [.seconds(30)])
}

@MainActor
@Test
func throttledStatusRefreshCoalescesRapidProgressUpdates() async {
    let sleeper = ControlledSleeper()
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        statusRefreshPolicy: .seconds(1),
        sleep: { duration in
            await sleeper.sleep(for: duration)
        }
    )
    store.connectionState = .connected
    var snapshots: [WidgetSnapshot] = []
    store.onWidgetSnapshotChange = { snapshots.append($0) }

    store.handle(event: .printerStatus(PrinterStatus(state: .printing, progress: 0.1)))
    store.handle(event: .printerStatusDelta(PrinterStatusDelta(progress: 0.2)))
    store.handle(event: .printerStatusDelta(PrinterStatusDelta(progress: 0.3)))
    await sleeper.waitForPendingSleepCount(1)

    #expect(store.printerStatus.progress == 0.1)
    #expect(snapshots.count == 1)

    await sleeper.resumeAll()
    for _ in 0..<10 {
        if snapshots.count == 2 { break }
        await Task.yield()
    }

    #expect(store.printerStatus.progress == 0.3)
    #expect(snapshots.count == 2)
    #expect(snapshots.last?.progressLabel == "30%")
}

@MainActor
@Test
func throttledStatusRefreshPublishesStateChangesImmediately() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: nil,
                appLanguage: .simplifiedChinese
            )
        ),
        statusRefreshPolicy: .seconds(10)
    )
    store.connectionState = .connected
    var snapshots: [WidgetSnapshot] = []
    store.onWidgetSnapshotChange = { snapshots.append($0) }

    store.handle(event: .printerStatus(PrinterStatus(state: .printing, progress: 0.1)))
    store.handle(event: .printerStatusDelta(PrinterStatusDelta(state: .paused, progress: 0.2)))

    #expect(store.printerStatus.state == .paused)
    #expect(store.printerStatus.progress == 0.2)
    #expect(snapshots.count == 2)
    #expect(snapshots.last?.statusLabel == "已暂停")
}

@MainActor
@Test
func disconnectDoesNotScheduleReconnectForClientDisconnectedEvent() async {
    let client = DisconnectEmittingMoonrakerClient()
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        ),
        retryPolicy: MoonrakerRetryPolicy(delays: [.zero, .zero, .zero]),
        statusSnapshotRefreshInterval: nil,
        sleep: { _ in }
    )

    store.start()
    try? await Task.sleep(for: .milliseconds(100))
    #expect(store.connectionState == .connected)

    store.disconnect()
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.connectionState == .disconnected)
    #expect(store.retryAttemptCount == 0)
    #expect(store.nextRetryAt == nil)
    #expect(!store.isWaitingForManualReconnect)
    #expect(await client.disconnectCallCount() == 1)
    #expect(await client.connectCallCount() == 1)
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
    #expect(store.cameraSnapshotUpdatedAt != nil)
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
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: nil,
                cameraSnapshotURL: nil,
                appLanguage: .japanese
            )
        )
    )

    let success = await store.fetchCameraSnapshot()

    #expect(!success)
    #expect(store.cameraSnapshotData == nil)
    #expect(store.cameraSnapshotUpdatedAt == nil)
    #expect(store.cameraSnapshotErrorMessage == "Enter an accessible camera snapshot URL first.")
    #expect(store.cameraSnapshotErrorMessage(language: .japanese) == "先にアクセス可能なカメラスナップショット URL を入力してください。")
    #expect(store.cameraSnapshotErrorMessage(language: .simplifiedChinese) == "请先填写可访问的相机快照地址。")
    #expect(!store.isFetchingCameraSnapshot)
}

@MainActor
@Test
func fetchCameraSnapshotLocalizesRawNetworkFailureForDisplay() async throws {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        cameraClient: StubMoonrakerCameraClient(snapshotResult: .failure(URLError(.notConnectedToInternet))),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: nil,
                cameraSnapshotURL: "http://camera.local/snapshot.jpg",
                appLanguage: .japanese
            )
        )
    )

    let success = await store.fetchCameraSnapshot()

    #expect(!success)
    #expect(store.cameraSnapshotData == nil)
    #expect(store.cameraSnapshotErrorMessage(language: .japanese) == "Moonraker に接続できません。アドレス、ポート、ネットワークを確認してください。")
    #expect(store.cameraSnapshotErrorMessage(language: .simplifiedChinese) == "无法连接到 Moonraker，请检查地址、端口或网络。")
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

    await waitUntil { store.currentPrintThumbnailData == thumbnailData }

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
    await waitUntil { store.isWaitingForManualCurrentPrintThumbnailRetry }

    #expect(store.currentPrintThumbnailData == nil)
    #expect(store.isWaitingForManualCurrentPrintThumbnailRetry)

    store.handle(event: .printerStatus(status))
    try? await Task.sleep(for: .milliseconds(100))

    #expect(store.currentPrintThumbnailData == nil)
    #expect(await client.rescanCallCount() == 1)

    store.retryCurrentPrintThumbnail()
    await waitUntil { store.currentPrintThumbnailData == thumbnailData }

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
    let client = ScriptedMoonrakerClient(eventsPerConnect: [[.failed("Connection timed out")]])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(),
        retryPolicy: MoonrakerRetryPolicy(delays: []),
        statusSnapshotRefreshInterval: nil,
        sleep: { _ in },
        logStore: logStore
    )

    let success = await store.saveConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: nil
    )
    #expect(success)

    try? await Task.sleep(for: .milliseconds(100))

    #expect(logStore.entries.contains(where: { $0.message.contains("Configuration saved") }))
    #expect(logStore.entries.contains(where: { $0.message.contains("Connecting to Moonraker") }))
    #expect(logStore.entries.contains(where: { $0.message.contains("Connection failed") }))
}

private actor NoopMoonrakerClient: MoonrakerClientProtocol {
    func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async {}

    func disconnect() async {}

    func fetchCurrentStatus(configuration: MoonrakerValidatedConfiguration) async throws -> PrinterStatus {
        PrinterStatus()
    }

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

private actor DisconnectEmittingMoonrakerClient: MoonrakerClientProtocol {
    private var eventHandler: (@Sendable (MoonrakerClientEvent) -> Void)?
    private var connectCalls = 0
    private var disconnectCalls = 0

    func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async {
        connectCalls += 1
        eventHandler = onEvent
        onEvent(.connected)
    }

    func disconnect() async {
        disconnectCalls += 1
        eventHandler?(.disconnected("Disconnected"))
    }

    func fetchCurrentStatus(configuration: MoonrakerValidatedConfiguration) async throws -> PrinterStatus {
        PrinterStatus()
    }

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

    func connectCallCount() -> Int {
        connectCalls
    }

    func disconnectCallCount() -> Int {
        disconnectCalls
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

private actor ControlledSleeper {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var durations: [Duration] = []

    func sleep(for duration: Duration) async {
        await withCheckedContinuation { continuation in
            durations.append(duration)
            continuations.append(continuation)
        }
    }

    func waitForPendingSleepCount(_ count: Int) async {
        while continuations.count < count {
            await Task.yield()
        }
    }

    func resumeAll() {
        let pending = continuations
        continuations.removeAll()
        durations.removeAll()
        pending.forEach { $0.resume() }
    }

    func resumeFirst(matching duration: Duration) {
        guard let index = durations.firstIndex(of: duration) else { return }
        let continuation = continuations.remove(at: index)
        durations.remove(at: index)
        continuation.resume()
    }

    func pendingDurations() -> [Duration] {
        durations
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

@MainActor
private func waitUntil(_ condition: @MainActor () -> Bool) async {
    for _ in 0..<50 {
        if condition() {
            return
        }
        try? await Task.sleep(for: .milliseconds(20))
    }
}

private actor ScriptedMoonrakerClient: MoonrakerClientProtocol {
    private let eventsPerConnect: [[MoonrakerClientEvent]]
    private let statusSnapshots: [PrinterStatus]
    private let metadataSequencesByFilename: [String: [MoonrakerFileMetadata]]
    private let thumbnailDataByPath: [String: Data]
    private var connectCalls = 0
    private var statusSnapshotFetches = 0
    private var rescanCalls = 0
    private var metadataFetchCounts: [String: Int] = [:]

    init(
        eventsPerConnect: [[MoonrakerClientEvent]],
        statusSnapshots: [PrinterStatus] = [],
        metadataSequencesByFilename: [String: [MoonrakerFileMetadata]] = [:],
        thumbnailDataByPath: [String: Data] = [:]
    ) {
        self.eventsPerConnect = eventsPerConnect
        self.statusSnapshots = statusSnapshots
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

    func fetchCurrentStatus(configuration: MoonrakerValidatedConfiguration) async throws -> PrinterStatus {
        defer { statusSnapshotFetches += 1 }
        guard !statusSnapshots.isEmpty else {
            return PrinterStatus()
        }
        return statusSnapshots[min(statusSnapshotFetches, statusSnapshots.count - 1)]
    }

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

    func fetchCurrentStatusCallCount() -> Int {
        statusSnapshotFetches
    }

    func rescanCallCount() -> Int {
        rescanCalls
    }
}
