import Foundation
import Testing
@testable import SelenophileKit

@Test
func appAppearanceModeInitializesKnownRawValues() {
    #expect(AppAppearanceMode(rawValue: "system") == .system)
    #expect(AppAppearanceMode(rawValue: "light") == .light)
    #expect(AppAppearanceMode(rawValue: "dark") == .dark)
}

@Test
func appAppearanceModeSupportedSelectionsMatchesDeclaredCases() {
    #expect(AppAppearanceMode.supportedSelections == Array(AppAppearanceMode.allCases))
    #expect(AppAppearanceMode.supportedSelections.count == 3)
}

@Test
func appAppearanceModeEncodesAndDecodesStableRawValues() throws {
    let data = try JSONEncoder().encode(AppAppearanceMode.light)
    let decoded = try JSONDecoder().decode(AppAppearanceMode.self, from: data)

    #expect(decoded == .light)
    #expect(String(data: data, encoding: .utf8) == #""light""#)
}

@Test
func appAppearanceModeProvidesStableLocalizationKeys() {
    #expect(AppAppearanceMode.system.localizationKey == .followSystem)
    #expect(AppAppearanceMode.light.localizationKey == .appearanceLightMode)
    #expect(AppAppearanceMode.dark.localizationKey == .appearanceDarkMode)
}
