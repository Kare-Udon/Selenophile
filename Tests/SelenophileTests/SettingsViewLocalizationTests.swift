import Foundation
import Testing
@testable import Selenophile
@testable import SelenophileKit

@MainActor
@Suite("SettingsViewLocalization")
struct SettingsViewLocalizationTests {
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

    @Test
    func settingsSubmissionDoesNotPersistAppearanceWhenConfigurationSaveFails() async {
        let defaults = UserDefaults(suiteName: "SettingsViewLocalizationTests.failedSubmit.\(UUID().uuidString)")!
        let appearanceStore = AppAppearanceStore(defaults: defaults)
        appearanceStore.save(mode: .dark, palette: .default)
        appearanceStore.preview(mode: .light, palette: .graphite)
        let store = PrinterStatusStore(
            client: SettingsViewLocalizationNoopClient(),
            persistence: SettingsViewLocalizationConfigurationStore(configuration: nil),
            logStore: AppLogStore()
        )

        let success = await SettingsViewSubmission.save(
            store: store,
            appAppearanceStore: appearanceStore,
            serverURLString: "",
            apiToken: " token ",
            cameraSnapshotURL: "",
            appLanguage: .english,
            appearanceMode: .light,
            themePalette: .graphite
        )

        #expect(!success)
        #expect(appearanceStore.selectedMode == .light)
        #expect(appearanceStore.selectedPalette == .graphite)
        #expect(appearanceStore.persistedMode == .dark)
        #expect(appearanceStore.persistedPalette == .default)

        appearanceStore.restorePersistedMode()

        #expect(appearanceStore.selectedMode == .dark)
        #expect(appearanceStore.selectedPalette == .default)
    }

    @Test
    func settingsSubmissionPersistsAppearanceAfterConfigurationSaveSucceeds() async {
        let defaults = UserDefaults(suiteName: "SettingsViewLocalizationTests.successfulSubmit.\(UUID().uuidString)")!
        let appearanceStore = AppAppearanceStore(defaults: defaults)
        appearanceStore.save(mode: .dark, palette: .default)
        let configurationStore = SettingsViewLocalizationConfigurationStore(configuration: nil)
        let store = PrinterStatusStore(
            client: SettingsViewLocalizationNoopClient(),
            persistence: configurationStore,
            logStore: AppLogStore()
        )

        let success = await SettingsViewSubmission.save(
            store: store,
            appAppearanceStore: appearanceStore,
            serverURLString: "http://printer.local:7125",
            apiToken: " token ",
            cameraSnapshotURL: " http://camera.local/snapshot.jpg ",
            appLanguage: .simplifiedChinese,
            appearanceMode: .light,
            themePalette: .graphite
        )

        #expect(success)
        #expect(appearanceStore.persistedMode == .light)
        #expect(appearanceStore.persistedPalette == .graphite)
        #expect(configurationStore.load()?.apiToken == "token")
        #expect(configurationStore.load()?.cameraSnapshotURL == "http://camera.local/snapshot.jpg")
        #expect(configurationStore.load()?.appLanguage == .simplifiedChinese)
    }
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
