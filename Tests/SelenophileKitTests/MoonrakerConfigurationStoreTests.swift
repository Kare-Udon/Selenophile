import Foundation
import Testing
@testable import SelenophileKit

@Test
func userDefaultsStoreSavesTokenToCredentialStoreAndRedactsDefaults() throws {
    let defaults = makeIsolatedDefaults()
    let credentialStore = RecordingCredentialStore()
    let store = UserDefaultsMoonrakerConfigurationStore(defaults: defaults, credentialStore: credentialStore)
    let configuration = MoonrakerConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "secret",
        cameraSnapshotURL: "/webcam/?action=snapshot",
        appLanguage: .english
    )

    store.save(configuration)

    #expect(credentialStore.token == "secret")
    let storedConfiguration = try #require(readStoredConfiguration(in: defaults))
    #expect(storedConfiguration.serverURLString == "http://printer.local:7125")
    #expect(storedConfiguration.apiToken == nil)
    #expect(storedConfiguration.cameraSnapshotURL == "/webcam/?action=snapshot")
    #expect(storedConfiguration.appLanguage == .english)
}

@Test
func userDefaultsStoreLoadsTokenFromCredentialStore() throws {
    let defaults = makeIsolatedDefaults()
    let credentialStore = RecordingCredentialStore(token: "secret")
    let store = UserDefaultsMoonrakerConfigurationStore(defaults: defaults, credentialStore: credentialStore)
    let configuration = MoonrakerConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: nil,
        cameraSnapshotURL: nil,
        appLanguage: .japanese
    )
    defaults.set(try JSONEncoder().encode(configuration), forKey: storedConfigurationKey)

    let loaded = try #require(store.load())

    #expect(loaded.apiToken == "secret")
    #expect(loaded.serverURLString == "http://printer.local:7125")
    #expect(loaded.appLanguage == .japanese)
}

@Test
func userDefaultsStoreMigratesLegacyTokenToCredentialStore() throws {
    let defaults = makeIsolatedDefaults()
    let credentialStore = RecordingCredentialStore()
    let store = UserDefaultsMoonrakerConfigurationStore(defaults: defaults, credentialStore: credentialStore)
    let legacyConfiguration = MoonrakerConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "legacy-secret",
        cameraSnapshotURL: "/webcam/?action=snapshot",
        appLanguage: .system
    )
    defaults.set(try JSONEncoder().encode(legacyConfiguration), forKey: storedConfigurationKey)

    let loaded = try #require(store.load())

    #expect(loaded.apiToken == "legacy-secret")
    #expect(credentialStore.token == "legacy-secret")
    let migratedConfiguration = try #require(readStoredConfiguration(in: defaults))
    #expect(migratedConfiguration.apiToken == nil)
    #expect(migratedConfiguration.cameraSnapshotURL == "/webcam/?action=snapshot")
}

@Test
func userDefaultsStoreKeepsLegacyTokenIfCredentialMigrationFails() throws {
    let defaults = makeIsolatedDefaults()
    let credentialStore = RecordingCredentialStore(shouldSaveSucceed: false)
    let store = UserDefaultsMoonrakerConfigurationStore(defaults: defaults, credentialStore: credentialStore)
    let legacyConfiguration = MoonrakerConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "legacy-secret",
        cameraSnapshotURL: nil,
        appLanguage: .system
    )
    defaults.set(try JSONEncoder().encode(legacyConfiguration), forKey: storedConfigurationKey)

    let loaded = try #require(store.load())

    #expect(loaded.apiToken == "legacy-secret")
    let persistedConfiguration = try #require(readStoredConfiguration(in: defaults))
    #expect(persistedConfiguration.apiToken == "legacy-secret")
}

@Test
func userDefaultsStoreClearRemovesDefaultsAndToken() throws {
    let defaults = makeIsolatedDefaults()
    let credentialStore = RecordingCredentialStore(token: "secret")
    let store = UserDefaultsMoonrakerConfigurationStore(defaults: defaults, credentialStore: credentialStore)
    store.save(
        MoonrakerConfiguration(
            serverURLString: "http://printer.local:7125",
            apiToken: "secret",
            cameraSnapshotURL: nil
        )
    )

    store.clear()

    #expect(defaults.data(forKey: storedConfigurationKey) == nil)
    #expect(credentialStore.token == nil)
    #expect(credentialStore.clearCount == 1)
}

private let storedConfigurationKey = "moonraker.configuration"

private func makeIsolatedDefaults() -> UserDefaults {
    let suiteName = "MoonrakerConfigurationStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

private func readStoredConfiguration(in defaults: UserDefaults) -> MoonrakerConfiguration? {
    guard let data = defaults.data(forKey: storedConfigurationKey) else {
        return nil
    }
    return try? JSONDecoder().decode(MoonrakerConfiguration.self, from: data)
}

private final class RecordingCredentialStore: MoonrakerCredentialStoring {
    var token: String?
    var clearCount = 0
    private let shouldSaveSucceed: Bool

    init(token: String? = nil, shouldSaveSucceed: Bool = true) {
        self.token = token
        self.shouldSaveSucceed = shouldSaveSucceed
    }

    func loadAPIToken() -> String? {
        token
    }

    @discardableResult
    func saveAPIToken(_ token: String?) -> Bool {
        guard shouldSaveSucceed else {
            return false
        }
        self.token = token
        return true
    }

    func clearAPIToken() {
        clearCount += 1
        token = nil
    }
}
