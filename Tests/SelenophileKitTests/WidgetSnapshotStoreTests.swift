import Foundation
import Testing
@testable import SelenophileKit

@Test
func widgetSnapshotStoreRoundTripsSnapshot() {
    let directoryURL = makeTemporaryDirectory()
    let store = WidgetSnapshotStore(containerURL: directoryURL)
    let snapshot = WidgetSnapshot(
        statusLabel: "打印中",
        connectionLabel: "已连接",
        title: "Benchy_0.2mm.gcode",
        progress: 0.64,
        progressLabel: "64%",
        remainingTime: "00:28:40",
        elapsedTime: "00:49:20",
        nozzle: "215.0 / 220.0°C",
        bed: "63.0 / 65.0°C",
        layer: "124 / 196",
        speed: "100%",
        summary: "正在稳定打印，状态正常",
        tone: .accent
    )

    store.save(snapshot)

    #expect(store.load() == snapshot)
}

@Test
func widgetSnapshotStoreClearsSavedFile() {
    let directoryURL = makeTemporaryDirectory()
    let store = WidgetSnapshotStore(containerURL: directoryURL)
    let snapshot = WidgetSnapshot.placeholder

    store.save(snapshot)
    #expect(FileManager.default.fileExists(atPath: store.fileURL.path))

    store.clear()

    #expect(store.load() == nil)
    #expect(!FileManager.default.fileExists(atPath: store.fileURL.path))
}

@Test
func widgetSnapshotStoreUsesStableFileName() {
    let directoryURL = makeTemporaryDirectory()
    let store = WidgetSnapshotStore(containerURL: directoryURL)

    #expect(store.fileURL.deletingLastPathComponent() == directoryURL)
    #expect(store.fileURL.lastPathComponent == AppConfig.widgetSnapshotFileName)
}

@MainActor
@Test
func printerStatusStoreExportsPlaceholderSnapshotWhenUnconfigured() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        cameraClient: NoopMoonrakerCameraClient(),
        persistence: StubMoonrakerConfigurationStore(configuration: nil)
    )

    let snapshot = store.widgetSnapshot()

    #expect(snapshot == .placeholder)
}

@MainActor
@Test
func printerStatusStoreExportsWidgetSnapshotFromLiveStatus() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        cameraClient: NoopMoonrakerCameraClient(),
        persistence: StubMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.connectionState = .connected
    store.printerStatus = PrinterStatus(
        state: .printing,
        filename: "Benchy_0.2mm.gcode",
        message: "正在稳定打印，状态正常",
        progress: 0.64,
        printDuration: 1_200,
        estimatedTimeRemaining: 1_720,
        layer: LayerStatus(current: 124, total: 196),
        bed: TemperatureStatus(actual: 63, target: 65),
        extruder: TemperatureStatus(actual: 215, target: 220),
        feedRateMultiplier: 1.0
    )

    let snapshot = store.widgetSnapshot()

    #expect(snapshot.statusLabel == "打印中")
    #expect(snapshot.connectionLabel == "已连接")
    #expect(snapshot.title == "Benchy_0.2mm.gcode")
    #expect(snapshot.progress == 0.64)
    #expect(snapshot.progressLabel == "64%")
    #expect(snapshot.remainingTime == "00:28:40")
    #expect(snapshot.elapsedTime == "00:20:00")
    #expect(snapshot.nozzle == "215.0 / 220.0°C")
    #expect(snapshot.bed == "63.0 / 65.0°C")
    #expect(snapshot.layer == "124 / 196")
    #expect(snapshot.speed == "100%")
    #expect(snapshot.summary == "正在稳定打印，状态正常")
    #expect(snapshot.tone == .accent)
}

private func makeTemporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private actor NoopMoonrakerClient: MoonrakerClientProtocol {
    func connect(
        configuration: MoonrakerValidatedConfiguration,
        onEvent: @escaping @Sendable (MoonrakerClientEvent) -> Void
    ) async {
    }

    func disconnect() async {
    }

    func rescanGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws {
    }

    func fetchGCodeMetadata(
        configuration: MoonrakerValidatedConfiguration,
        filename: String
    ) async throws -> MoonrakerFileMetadata {
        MoonrakerFileMetadata(filename: nil, estimatedTime: nil, thumbnails: nil)
    }

    func fetchGCodeThumbnail(
        configuration: MoonrakerValidatedConfiguration,
        filename: String,
        relativePath: String
    ) async throws -> Data {
        Data()
    }
}

private actor NoopMoonrakerCameraClient: MoonrakerCameraClientProtocol {
    func fetchSnapshot(configuration: MoonrakerValidatedConfiguration) async throws -> Data {
        Data()
    }
}

private struct StubMoonrakerConfigurationStore: MoonrakerConfigurationPersisting {
    let configuration: MoonrakerConfiguration?

    func load() -> MoonrakerConfiguration? {
        configuration
    }

    func save(_ configuration: MoonrakerConfiguration) {
    }

    func clear() {
    }
}
