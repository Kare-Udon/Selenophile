import Foundation
import Testing
@testable import Selenophile

@MainActor
@Test
func appUpdateDefaultsUseDailyAutomaticCheckInterval() {
    #expect(AppUpdateDefaults.automaticCheckInterval == 86_400)
}

@MainActor
@Test
func appUpdateConfigurationAcceptsRealHTTPSFeedAndPublicKey() throws {
    let bundle = try makeUpdateConfigurationBundle(
        feedURL: "https://kare-udon.github.io/Selenophile/selenophile/appcast.xml",
        publicKey: "E/nueJJiuhX7I3zRZEjCtYn50JepeMIbY1LltoIs6rA="
    )

    #expect(AppUpdateConfiguration.isConfigured(bundle: bundle))
}

@MainActor
@Test
func appUpdateConfigurationRejectsPlaceholderFeedOrPublicKey() throws {
    let placeholderFeedBundle = try makeUpdateConfigurationBundle(
        feedURL: "https://example.com/appcast.xml",
        publicKey: "E/nueJJiuhX7I3zRZEjCtYn50JepeMIbY1LltoIs6rA="
    )
    let placeholderKeyBundle = try makeUpdateConfigurationBundle(
        feedURL: "https://kare-udon.github.io/Selenophile/selenophile/appcast.xml",
        publicKey: "$(SPARKLE_PUBLIC_ED_KEY)"
    )

    #expect(!AppUpdateConfiguration.isConfigured(bundle: placeholderFeedBundle))
    #expect(!AppUpdateConfiguration.isConfigured(bundle: placeholderKeyBundle))
}

private func makeUpdateConfigurationBundle(
    feedURL: String,
    publicKey: String
) throws -> Bundle {
    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let bundleURL = rootURL.appendingPathComponent("Fake.app", isDirectory: true)
    let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)

    try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
    let plist: [String: Any] = [
        "CFBundleIdentifier": "com.udon.selenophile.tests.\(UUID().uuidString)",
        "CFBundlePackageType": "APPL",
        "SUFeedURL": feedURL,
        "SUPublicEDKey": publicKey
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try data.write(to: contentsURL.appendingPathComponent("Info.plist"))

    return try #require(Bundle(url: bundleURL))
}
