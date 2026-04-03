import Foundation
import Testing
@testable import SelenophileKit

@Test
func appLocalizationLoadsSettingsWindowTitleFromBundles() {
    #expect(AppLocalization.localizedString(.settingsWindowTitle, language: .english) == "Moonraker Settings")
    #expect(AppLocalization.localizedString(.settingsWindowTitle, language: .simplifiedChinese) == "Moonraker 设置")
    #expect(AppLocalization.localizedString(.settingsWindowTitle, language: .traditionalChinese) == "Moonraker 設定")
}

@Test
func appLocalizationLoadsLogWindowTitleFromBundles() {
    #expect(AppLocalization.localizedString(.logWindowTitle, language: .english) == "Debug Logs")
    #expect(AppLocalization.localizedString(.logWindowTitle, language: .simplifiedChinese) == "调试日志")
    #expect(AppLocalization.localizedString(.logWindowTitle, language: .traditionalChinese) == "除錯記錄")
}

@Test
func appLocalizationFallsBackToEnglishBaseValueWhenTranslationIsMissing() {
    #expect(AppLocalization.localizedString(.fallbackProbeTitle, language: .simplifiedChinese) == "Fallback Probe")
    #expect(AppLocalization.localizedString(.fallbackProbeTitle, language: .traditionalChinese) == "Fallback Probe")
    #expect(AppLocalization.localizedString("missing_probe_key", fallback: "English Base", language: .japanese) == "English Base")
}

@Test
func appLocalizationProvidesFollowSystemLabel() {
    #expect(AppLocalization.localizedString(.followSystem, language: .english) == "Follow System")
}

@Test
func appLocalizationLoadsTranslationsFromEmbeddedResourceBundle() throws {
    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let appBundleURL = rootURL.appendingPathComponent("Fake.app", isDirectory: true)
    let appResourcesURL = appBundleURL.appendingPathComponent("Contents/Resources", isDirectory: true)
    let nestedBundleURL = appResourcesURL.appendingPathComponent("Selenophile_SelenophileKit.bundle", isDirectory: true)
    let nestedResourcesURL = nestedBundleURL.appendingPathComponent("Contents/Resources", isDirectory: true)
    let japaneseLocalizationURL = nestedResourcesURL.appendingPathComponent("ja.lproj", isDirectory: true)

    try FileManager.default.createDirectory(at: japaneseLocalizationURL, withIntermediateDirectories: true)
    try """
    "settings_window_title" = "Moonraker 設定（埋め込み）";
    """.write(
        to: japaneseLocalizationURL.appendingPathComponent("Localizable.strings"),
        atomically: true,
        encoding: .utf8
    )

    let appBundle = try #require(Bundle(url: appBundleURL))

    let localized = AppLocalization.localizedString(
        "settings_window_title",
        fallback: "Moonraker Settings",
        language: .japanese,
        candidateBundles: [appBundle]
    )

    #expect(localized == "Moonraker 設定（埋め込み）")
}
