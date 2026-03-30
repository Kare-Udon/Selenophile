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
