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
func appLocalizationUsesPlainSaveActionsForSettingsFooter() {
    #expect(AppLocalization.localizedString(.settingsSave, language: .english) == "Save")
    #expect(AppLocalization.localizedString(.settingsSaving, language: .english) == "Saving…")
    #expect(AppLocalization.localizedString(.settingsTestingConnection, language: .english) == "Testing…")
    #expect(AppLocalization.localizedString(.settingsSave, language: .simplifiedChinese) == "保存")
    #expect(AppLocalization.localizedString(.settingsSave, language: .japanese) == "保存")
}

@Test
func appLocalizationDescribesAboutDependencies() {
    #expect(AppLocalization.localizedString(.settingsAboutDependenciesTitle, language: .english) == "Dependencies")
    #expect(AppLocalization.localizedString(.settingsAboutDependenciesTitle, language: .simplifiedChinese) == "项目依赖")
    #expect(AppLocalization.localizedString(.settingsDependencyMoonraker, language: .english).contains("printer status"))
    #expect(AppLocalization.localizedString(.settingsDependencyMoonraker, language: .simplifiedChinese).contains("打印状态"))
}

@Test
func appLocalizationDescribesUpdateSettings() {
    #expect(AppLocalization.localizedString(.settingsUpdatesStatusReady, language: .english) == "Update checking is ready.")
    #expect(AppLocalization.localizedString(.settingsAutomaticUpdatesLabel, language: .english) == "Automatic Update Checks")
    #expect(AppLocalization.localizedString(.settingsAutomaticUpdatesLabel, language: .simplifiedChinese) == "自动检查更新")
    #expect(AppLocalization.localizedString(.settingsAutomaticUpdatesLabel, language: .japanese) == "自動アップデート確認")
}

@Test
func appLocalizationProvidesAboutDependencyTranslationsForEveryLanguage() {
    let dependencyKeys: [AppLocalization.Key] = [
        .settingsAboutDependenciesTitle,
        .settingsAboutDependenciesIntro,
        .settingsDependencySwift,
        .settingsDependencySwiftUI,
        .settingsDependencyAppKit,
        .settingsDependencyWidgetKit,
        .settingsDependencyServiceManagement,
        .settingsDependencyMoonraker,
        .settingsDependencyTuist,
        .settingsDependencySparkle
    ]
    let translatedLanguages = AppLanguage.supportedSelections.filter {
        $0 != .system && $0 != .english
    }

    for language in translatedLanguages {
        for key in dependencyKeys {
            let localized = AppLocalization.localizedString(key, language: language)
            #expect(localized != key.fallbackValue)
        }
    }
}

@Test
func appLocalizationLocalizesJapaneseSettingsSurface() {
    #expect(AppLocalization.localizedString(.settingsConnectionSection, language: .japanese) == "接続")
    #expect(AppLocalization.localizedString(.settingsGeneralSection, language: .japanese) == "一般")
    #expect(AppLocalization.localizedString(.settingsAppearanceSection, language: .japanese) == "外観")
    #expect(AppLocalization.localizedString(.settingsTestConnection, language: .japanese) == "接続をテスト")
    #expect(AppLocalization.localizedString(.settingsTestingConnection, language: .japanese) == "テスト中…")
    #expect(AppLocalization.localizedString(.settingsConnectionHint, language: .japanese) == "Moonraker インスタンスに接続するための URL とトークンを入力してください。")
    #expect(AppLocalization.localizedString(.settingsStatusRefreshRateLabel, language: .japanese) == "状態の更新頻度")
    #expect(AppLocalization.localizedString(.settingsStatusRefreshRealtime, language: .japanese) == "リアルタイム")
    #expect(AppLocalization.localizedString(.appearanceModeLabel, language: .japanese) == "テーマ")
    #expect(AppLocalization.localizedString(.themePaletteLabel, language: .japanese) == "カラースタイル")
}

@Test
func appLocalizationLocalizesJapaneseConnectionStatusSurface() {
    #expect(AppLocalization.localizedString(.menuConnectionBadgeNeedsAttention, language: .japanese) == "要対応")
    #expect(AppLocalization.localizedString(.connectionSummaryAutoRetryStopped, language: .japanese) == "自動再試行は停止しました。手動で再接続してください。")
    #expect(AppLocalization.localizedString(.connectionErrorCannotConnect, language: .japanese) == "Moonraker に接続できません。アドレス、ポート、ネットワークを確認してください。")
    #expect(AppLocalization.localizedString(.cameraErrorNoSnapshotURL, language: .japanese) == "先にアクセス可能なカメラスナップショット URL を入力してください。")
    #expect(AppLocalization.localizedString(.printerStatePrinting, language: .japanese) == "印刷中")
    #expect(AppLocalization.localizedString(.widgetTitleNoPrintTask, language: .japanese) == "現在の印刷ジョブはありません")
}

@Test
func appLocalizationMapsCommonURLSessionConnectionFailures() {
    let messages = [
        "Could not connect to the server.",
        "Unable to connect to the server.",
        "The Internet connection appears to be offline.",
        "A server with the specified hostname could not be found.",
        "The network connection was lost.",
        "The operation couldn’t be completed. Network is unreachable.",
        "The operation couldn’t be completed. Not connected to the Internet.",
        "Connection reset by peer.",
        "The operation couldn’t be completed. (NSURLErrorDomain error -1011.)",
        "bad server response"
    ]

    for message in messages {
        #expect(
            AppLocalization.localizedConnectionErrorMessage(message, language: .japanese)
                == "Moonraker に接続できません。アドレス、ポート、ネットワークを確認してください。"
        )
    }
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
