import Foundation
import Testing
@testable import SelenophileKit

@Test
func widgetSnapshotEncodesAndDecodesLosslessly() throws {
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

    let data = try JSONEncoder().encode(snapshot)
    let decoded = try JSONDecoder().decode(WidgetSnapshot.self, from: data)

    #expect(decoded == snapshot)
}

@Test
func widgetSnapshotStoreRoundTripsSnapshot() {
    let directoryURL = makeTemporaryDirectory()
    let store = WidgetSnapshotStore(fileManager: MockFileManager(containerURL: directoryURL))
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
    let store = WidgetSnapshotStore(fileManager: MockFileManager(containerURL: directoryURL))
    let snapshot = WidgetSnapshot.placeholder

    store.save(snapshot)
    #expect(store.fileURL.map { FileManager.default.fileExists(atPath: $0.path) } == true)

    store.clear()

    #expect(store.load() == nil)
    #expect(store.fileURL.map { FileManager.default.fileExists(atPath: $0.path) } == false)
}

@Test
func widgetSnapshotStoreUsesStableFileName() {
    let directoryURL = makeTemporaryDirectory()
    let store = WidgetSnapshotStore(fileManager: MockFileManager(containerURL: directoryURL))

    #expect(store.fileURL?.deletingLastPathComponent() == directoryURL)
    #expect(store.fileURL?.lastPathComponent == AppConfig.widgetSnapshotFileName)
}

@Test
func widgetSnapshotStoreIgnoresMissingAppGroupContainer() {
    let store = WidgetSnapshotStore(fileManager: MockFileManager(containerURL: nil))

    #expect(store.load() == nil)

    store.save(.placeholder)
    store.clear()
    #expect(store.fileURL == nil)
}

private func makeTemporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private final class MockFileManager: FileManager {
    private let containerURL: URL?

    init(containerURL: URL?) {
        self.containerURL = containerURL
        super.init()
    }

    override func containerURL(forSecurityApplicationGroupIdentifier identifier: String) -> URL? {
        containerURL
    }
}
