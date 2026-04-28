import Foundation
import Testing
@testable import SelenophileKit

@Test
func appThemePaletteInitializesKnownRawValues() {
    #expect(AppThemePalette(rawValue: "default") == .default)
    #expect(AppThemePalette(rawValue: "graphite") == .graphite)
    #expect(AppThemePalette(rawValue: "github") == .github)
    #expect(AppThemePalette(rawValue: "tokyoNight") == .tokyoNight)
    #expect(AppThemePalette(rawValue: "oneDark") == .oneDark)
    #expect(AppThemePalette(rawValue: "unknown") == nil)
}

@Test
func appThemePaletteSupportedSelectionsMatchesDeclaredCases() {
    #expect(AppThemePalette.supportedSelections == Array(AppThemePalette.allCases))
    #expect(AppThemePalette.supportedSelections.count == 5)
}

@Test
func appThemePaletteEncodesAndDecodesStableRawValues() throws {
    let data = try JSONEncoder().encode(AppThemePalette.tokyoNight)
    let decoded = try JSONDecoder().decode(AppThemePalette.self, from: data)

    #expect(decoded == .tokyoNight)
}

@Test
func appThemePaletteProvidesStableLocalizationKeys() {
    #expect(AppThemePalette.default.localizationKey == .themePaletteDefault)
    #expect(AppThemePalette.graphite.localizationKey == .themePaletteGraphite)
    #expect(AppThemePalette.github.localizationKey == .themePaletteGitHub)
    #expect(AppThemePalette.tokyoNight.localizationKey == .themePaletteTokyoNight)
    #expect(AppThemePalette.oneDark.localizationKey == .themePaletteOneDark)
}
