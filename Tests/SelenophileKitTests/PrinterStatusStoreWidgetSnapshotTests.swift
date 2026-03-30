import Foundation
import Testing
@testable import SelenophileKit

@MainActor
@Test
func widgetSnapshotDefaultsToPlaceholderWhenUnconfigured() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(configuration: nil)
    )

    #expect(store.widgetSnapshot() == .placeholder)
}

@MainActor
@Test
func widgetSnapshotReflectsConnectedPrintingState() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.connectionState = .connected
    store.printerStatus = PrinterStatus(
        state: .printing,
        filename: "benchy.gcode",
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
    #expect(snapshot.title == "benchy.gcode")
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

@MainActor
@Test
func widgetSnapshotReflectsConnectedStandbyState() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.connectionState = .connected
    store.printerStatus = PrinterStatus(
        state: .standby,
        filename: nil,
        message: nil,
        progress: nil,
        printDuration: nil,
        estimatedTimeRemaining: nil,
        layer: nil,
        bed: nil,
        extruder: nil,
        feedRateMultiplier: nil
    )

    let snapshot = store.widgetSnapshot()

    #expect(snapshot.statusLabel == "待机")
    #expect(snapshot.connectionLabel == "已连接")
    #expect(snapshot.title == "当前无打印任务")
    #expect(snapshot.progress == 0)
    #expect(snapshot.progressLabel == "0%")
    #expect(snapshot.remainingTime == "--:--:--")
    #expect(snapshot.nozzle == "--")
    #expect(snapshot.bed == "--")
    #expect(snapshot.layer == "--")
    #expect(snapshot.speed == "--")
    #expect(snapshot.summary == "打印机已连接，当前没有活动任务")
    #expect(snapshot.tone == .muted)
}

@MainActor
@Test
func widgetSnapshotReflectsDisconnectedState() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )

    store.connectionState = .disconnected
    store.lastErrorMessage = "连接超时"
    store.printerStatus = PrinterStatus()

    let snapshot = store.widgetSnapshot()

    #expect(snapshot.statusLabel == "已断开")
    #expect(snapshot.connectionLabel == "已断开")
    #expect(snapshot.tone == .danger)
    #expect(snapshot.summary == "连接超时")
}

@MainActor
@Test
func widgetSnapshotChangeCallbackEmitsUpdatedSnapshot() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )
    var snapshots: [WidgetSnapshot] = []
    store.onWidgetSnapshotChange = { snapshots.append($0) }
    store.connectionState = .connected

    store.handle(
        event: .printerStatus(
            PrinterStatus(
                state: .printing,
                filename: "benchy.gcode",
                progress: 0.5,
                printDuration: 600,
                estimatedTimeRemaining: 600,
                layer: LayerStatus(current: 1, total: 2),
                bed: TemperatureStatus(actual: 60, target: 65),
                extruder: TemperatureStatus(actual: 210, target: 220),
                feedRateMultiplier: 1.0
            )
        )
    )

    #expect(snapshots.count == 1)
    #expect(snapshots.first?.statusLabel == "打印中")
    #expect(snapshots.first?.progressLabel == "50%")
}

@MainActor
@Test
func failedEventPublishesDangerToneSnapshot() {
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
        )
    )
    var snapshots: [WidgetSnapshot] = []
    store.onWidgetSnapshotChange = { snapshots.append($0) }

    store.handle(event: .failed("连接超时"))

    #expect(snapshots.count == 1)
    #expect(snapshots.first?.statusLabel == "连接失败")
    #expect(snapshots.first?.connectionLabel == "连接失败")
    #expect(snapshots.first?.tone == .danger)
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

private struct InMemoryMoonrakerConfigurationStore: MoonrakerConfigurationPersisting {
    var configuration: MoonrakerConfiguration?

    func load() -> MoonrakerConfiguration? {
        configuration
    }

    func save(_ configuration: MoonrakerConfiguration) {}

    func clear() {}
}
