import Foundation
import Testing
@testable import Selenophile
@testable import SelenophileKit

@MainActor
@Test
func settingsViewLocalizedTextLanguageFollowsAppLanguageStoreChanges() {
    let logStore = AppLogStore()
    let configurationStore = SettingsViewLocalizationConfigurationStore(
        configuration: MoonrakerConfiguration(
            serverURLString: "http://printer.local:7125",
            apiToken: nil,
            cameraSnapshotURL: nil,
            appLanguage: .english
        )
    )
    let store = PrinterStatusStore(
        client: SettingsViewLocalizationNoopClient(),
        persistence: configurationStore,
        logStore: logStore
    )
    let languageStore = AppLanguageStore(selectedLanguage: .english)
    let appearanceStore = AppAppearanceStore(
        defaults: UserDefaults(suiteName: "SettingsViewLocalizationTests.\(UUID().uuidString)")!
    )
    let settingsView = SettingsView(
        store: store,
        onClose: {},
        onCancel: {},
        appLanguageStore: languageStore,
        appAppearanceStore: appearanceStore
    )

    #expect(settingsView.languageForLocalizedText(preferredLanguages: ["zh-CN"]) == .english)

    languageStore.update(selectedLanguage: .simplifiedChinese)

    #expect(settingsView.languageForLocalizedText(preferredLanguages: ["zh-CN"]) == .simplifiedChinese)
}

private final class SettingsViewLocalizationConfigurationStore: MoonrakerConfigurationPersisting {
    private var configuration: MoonrakerConfiguration?

    init(configuration: MoonrakerConfiguration?) {
        self.configuration = configuration
    }

    func load() -> MoonrakerConfiguration? {
        configuration
    }

    func save(_ configuration: MoonrakerConfiguration) {
        self.configuration = configuration
    }

    func clear() {
        configuration = nil
    }
}

private actor SettingsViewLocalizationNoopClient: MoonrakerClientProtocol {
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
