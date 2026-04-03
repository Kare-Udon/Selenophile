import Foundation
import Testing
@testable import Selenophile
@testable import SelenophileKit

@MainActor
@Test
func appLanguageStoreDerivesLocaleFromSavedConfiguration() {
    let store = AppLanguageStore(selectedLanguage: .traditionalChinese)

    #expect(store.selectedLanguage == .traditionalChinese)
    #expect(store.locale.identifier == "zh-Hant")
}

@MainActor
@Test
func appLanguageStoreTreatsSystemSelectionAsResolvedLocale() {
    let store = AppLanguageStore(selectedLanguage: .system)

    #expect(store.resolvedLocale(preferredLanguages: ["zh-CN"]).identifier == "zh-Hans")
    #expect(store.resolvedLocale(preferredLanguages: ["zh-HK"]).identifier == "zh-Hant")
}

@MainActor
@Test
func appDelegateUpdatesLanguageStateAfterSavingConfiguration() async {
    let logStore = AppLogStore()
    let configurationStore = InMemoryMoonrakerConfigurationStore(configuration: nil)
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: configurationStore,
        logStore: logStore
    )
    let languageStore = AppLanguageStore(selectedLanguage: .system)
    let appDelegate = AppDelegate(
        logStore: logStore,
        store: store,
        appLanguageStore: languageStore,
        widgetCenter: WidgetCenterRecorder()
    )

    #expect(appDelegate.settingsWindowTitle() == "Moonraker Settings")

    let success = await store.saveConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: nil,
        appLanguage: .simplifiedChinese
    )

    #expect(success)
    #expect(languageStore.selectedLanguage == .simplifiedChinese)
    #expect(languageStore.locale.identifier == "zh-Hans")
    #expect(appDelegate.settingsWindowTitle() == "Moonraker 设置")
}

@MainActor
@Test
func appDelegatePreviewsLanguageSelectionBeforeSavingConfiguration() {
    let logStore = AppLogStore()
    let configurationStore = InMemoryMoonrakerConfigurationStore(configuration: nil)
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: configurationStore,
        logStore: logStore
    )
    let languageStore = AppLanguageStore(selectedLanguage: .system)
    let appDelegate = AppDelegate(
        logStore: logStore,
        store: store,
        appLanguageStore: languageStore,
        widgetCenter: WidgetCenterRecorder()
    )

    appDelegate.previewLanguageSelection(.simplifiedChinese)

    #expect(languageStore.selectedLanguage == .simplifiedChinese)
    #expect(appDelegate.settingsWindowTitle() == "Moonraker 设置")
}

@MainActor
@Test
func appDelegateRestoresPersistedLanguageSelectionAfterCancellingPreview() {
    let logStore = AppLogStore()
    let configurationStore = InMemoryMoonrakerConfigurationStore(
        configuration: MoonrakerConfiguration(
            serverURLString: "http://printer.local:7125",
            apiToken: nil,
            cameraSnapshotURL: nil,
            appLanguage: .traditionalChinese
        )
    )
    let store = PrinterStatusStore(
        client: NoopMoonrakerClient(),
        persistence: configurationStore,
        logStore: logStore
    )
    let languageStore = AppLanguageStore(selectedLanguage: .system)
    let appDelegate = AppDelegate(
        logStore: logStore,
        store: store,
        appLanguageStore: languageStore,
        widgetCenter: WidgetCenterRecorder()
    )

    appDelegate.previewLanguageSelection(.simplifiedChinese)
    appDelegate.restorePersistedLanguageSelection()

    #expect(languageStore.selectedLanguage == .traditionalChinese)
    #expect(appDelegate.settingsWindowTitle() == "Moonraker 設定")
}

private final class WidgetCenterRecorder: WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String) {}
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
