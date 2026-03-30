import Foundation
import Testing
@testable import SelenophileKit

@Test
func appLanguageInitializesKnownRawValues() {
    #expect(AppLanguage(rawValue: "system") == .system)
    #expect(AppLanguage(rawValue: "en") == .english)
    #expect(AppLanguage(rawValue: "zh-Hans") == .simplifiedChinese)
    #expect(AppLanguage(rawValue: "zh-Hant") == .traditionalChinese)
    #expect(AppLanguage(rawValue: "pt-BR") == .brazilianPortuguese)
    #expect(AppLanguage(rawValue: "ur") == .urdu)
}

@Test
func appLanguageProvidesStableLocaleIdentifiers() {
    #expect(AppLanguage.system.localeIdentifier == nil)
    #expect(AppLanguage.english.localeIdentifier == "en")
    #expect(AppLanguage.simplifiedChinese.localeIdentifier == "zh-Hans")
    #expect(AppLanguage.traditionalChinese.localeIdentifier == "zh-Hant")
    #expect(AppLanguage.brazilianPortuguese.localeIdentifier == "pt-BR")
}

@Test
func appLanguageProvidesResolvedLocaleIdentifiers() {
    #expect(AppLanguage.system.resolvedLocaleIdentifier(preferredLanguages: ["zh-CN"]) == "zh-Hans")
    #expect(AppLanguage.system.resolvedLocaleIdentifier(preferredLanguages: ["zh-TW"]) == "zh-Hant")
    #expect(AppLanguage.system.resolvedLocaleIdentifier(preferredLanguages: ["it-IT"]) == "en")
    #expect(AppLanguage.english.resolvedLocaleIdentifier() == "en")
}

@Test
func appLanguageResolvesSystemPreferenceFromPreferredLanguages() {
    #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-CN"]) == .simplifiedChinese)
    #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-TW"]) == .traditionalChinese)
    #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-HK"]) == .traditionalChinese)
    #expect(AppLanguage.system.resolved(preferredLanguages: ["zh-MO"]) == .traditionalChinese)
    #expect(AppLanguage.system.resolved(preferredLanguages: ["en-GB"]) == .english)
    #expect(AppLanguage.system.resolved(preferredLanguages: ["pt-PT"]) == .brazilianPortuguese)
    #expect(AppLanguage.system.resolved(preferredLanguages: ["it-IT"]) == .english)
    #expect(AppLanguage.system.resolved(preferredLanguages: []) == .english)
}

@Test
func appLanguageResolvesAllSupportedPrimaryLanguageCodes() {
    #expect(AppLanguage.resolvePreferredLanguage(from: ["es-MX"]) == .spanish)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["hi-IN"]) == .hindi)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ar-SA"]) == .arabic)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["bn-BD"]) == .bengali)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ru-RU"]) == .russian)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ja-JP"]) == .japanese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["pa-IN"]) == .punjabi)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["de-DE"]) == .german)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["jv-ID"]) == .javanese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ko-KR"]) == .korean)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["fr-FR"]) == .french)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["te-IN"]) == .telugu)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["mr-IN"]) == .marathi)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["tr-TR"]) == .turkish)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ta-IN"]) == .tamil)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["vi-VN"]) == .vietnamese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ur-PK"]) == .urdu)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["pt"]) == .brazilianPortuguese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["zh"]) == .simplifiedChinese)
}

@Test
func appLanguageResolvesUnderscoreFormatsAndPrefersEarlierEntries() {
    #expect(AppLanguage.resolvePreferredLanguage(from: ["pt_BR"]) == .brazilianPortuguese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["it-IT", "ja-JP"]) == .japanese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ZH-hant"]) == .traditionalChinese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["zh-TW"]) == .traditionalChinese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["zh-HK"]) == .traditionalChinese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["zh-MO"]) == .traditionalChinese)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["en_gb", "PT_br"]) == .english)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["fr-CA", "pt"]) == .french)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["pap-AW"]) == .english)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["ptx-PT"]) == .english)
    #expect(AppLanguage.resolvePreferredLanguage(from: ["pap-AW", "zh-Hant"]) == .traditionalChinese)
}

@Test
func appLanguageSupportedSelectionsMatchesDeclaredCases() {
    #expect(AppLanguage.supportedSelections == Array(AppLanguage.allCases))
    #expect(AppLanguage.supportedSelections.count == 22)
}

@Test
func appLanguageProvidesLocalizedDisplayNameForFollowSystem() {
    #expect(AppLanguage.system.displayName(in: .english) == "Follow System")
}
