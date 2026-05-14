import Foundation
import Testing
@testable import Selenophile
@testable import SelenophileKit

@MainActor
@Test
func appDelegatePublishesAndRefreshesWidgetSnapshots() {
    let logStore = AppLogStore()
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: InMemoryMoonrakerConfigurationStore(
            configuration: MoonrakerConfiguration(
                serverURLString: "http://printer.local:7125",
                apiToken: nil,
                appLanguage: .simplifiedChinese
            )
        ),
        logStore: logStore
    )
    let widgetStore = WidgetSnapshotStore(fileManager: MockFileManager(containerURL: makeTemporaryDirectory()))
    let widgetCenter = WidgetCenterRecorder()

    let appDelegate = AppDelegate(
        logStore: logStore,
        store: store,
        appLanguageStore: AppLanguageStore(selectedLanguage: .simplifiedChinese),
        widgetSnapshotStore: widgetStore,
        widgetCenter: widgetCenter
    )

    appDelegate.applicationDidFinishLaunching(Notification(name: Notification.Name("TestLaunch")))

    #expect(widgetCenter.reloadKinds.count == 2)
    #expect(widgetCenter.reloadKinds.allSatisfy { $0 == AppConfig.widgetKind })
    #expect(widgetStore.load()?.statusLabel == "连接中")

    store.disconnect()

    #expect(widgetCenter.reloadKinds.count == 3)
    #expect(widgetStore.load()?.statusLabel == "已断开")
    #expect(widgetStore.load()?.connectionLabel == "已断开")
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

private final class WidgetCenterRecorder: WidgetTimelineReloading {
    private(set) var reloadKinds: [String] = []

    func reloadTimelines(ofKind kind: String) {
        reloadKinds.append(kind)
    }
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
