import Testing
@testable import SelenophileKit

@Test
func appMetadataMatchesProjectIdentity() {
    #expect(AppConfig.appName == "Selenophile")
    #expect(AppConfig.bundleIdentifier == "com.udon.selenophile")
    #expect(AppConfig.menuTitle == "Selenophile")
}

@Test
func appConfigLocalizesSettingsWindowTitle() {
    #expect(AppConfig.settingsWindowTitle(for: .english) == "Moonraker Settings")
    #expect(AppConfig.settingsWindowTitle(for: .simplifiedChinese) == "Moonraker 设置")
    #expect(AppConfig.settingsWindowTitle(for: .traditionalChinese) == "Moonraker 設定")
}

@Test
func appConfigLocalizesLogWindowTitle() {
    #expect(AppConfig.logWindowTitle(for: .english) == "Debug Logs")
    #expect(AppConfig.logWindowTitle(for: .simplifiedChinese) == "调试日志")
    #expect(AppConfig.logWindowTitle(for: .traditionalChinese) == "除錯記錄")
}
