import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case spanish = "es"
    case hindi = "hi"
    case arabic = "ar"
    case brazilianPortuguese = "pt-BR"
    case bengali = "bn"
    case russian = "ru"
    case japanese = "ja"
    case punjabi = "pa"
    case german = "de"
    case javanese = "jv"
    case korean = "ko"
    case french = "fr"
    case telugu = "te"
    case marathi = "mr"
    case turkish = "tr"
    case tamil = "ta"
    case vietnamese = "vi"
    case urdu = "ur"

    public static var supportedSelections: [AppLanguage] {
        Self.allCases
    }

    public func displayName(in uiLanguage: AppLanguage) -> String {
        if self == .system {
            return AppLocalization.localizedString(.followSystem, language: uiLanguage)
        }

        let localeIdentifier = uiLanguage.resolved().localeIdentifier ?? AppLanguage.english.rawValue
        let displayLocale = Locale(identifier: localeIdentifier)
        return displayLocale.localizedString(forIdentifier: rawValue)
            ?? displayLocale.localizedString(forLanguageCode: rawValue)
            ?? rawValue
    }

    public var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        default:
            return rawValue
        }
    }

    public var resolvedLocaleIdentifier: String {
        resolvedLocaleIdentifier(preferredLanguages: Locale.preferredLanguages)
    }

    public func resolvedLocaleIdentifier(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        resolved(preferredLanguages: preferredLanguages).localeIdentifier ?? Self.english.rawValue
    }

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        switch self {
        case .system:
            return Self.resolvePreferredLanguage(from: preferredLanguages)
        default:
            return self
        }
    }

    public static func resolvePreferredLanguage(from preferredLanguages: [String]) -> AppLanguage {
        for identifier in preferredLanguages {
            if let language = Self.match(preferredLanguageIdentifier: identifier) {
                return language
            }
        }

        return .english
    }

    private static func match(preferredLanguageIdentifier identifier: String) -> AppLanguage? {
        let components = normalizedLanguageComponents(from: identifier)
        guard let languageCode = components.languageCode else {
            return nil
        }

        switch languageCode {
        case "zh":
            return resolveChineseLanguage(from: components)
        case "en":
            return .english
        case "es":
            return .spanish
        case "hi":
            return .hindi
        case "ar":
            return .arabic
        case "pt":
            return .brazilianPortuguese
        case "bn":
            return .bengali
        case "ru":
            return .russian
        case "ja":
            return .japanese
        case "pa":
            return .punjabi
        case "de":
            return .german
        case "jv":
            return .javanese
        case "ko":
            return .korean
        case "fr":
            return .french
        case "te":
            return .telugu
        case "mr":
            return .marathi
        case "tr":
            return .turkish
        case "ta":
            return .tamil
        case "vi":
            return .vietnamese
        case "ur":
            return .urdu
        default:
            return nil
        }
    }

    private static func resolveChineseLanguage(from components: LanguageComponents) -> AppLanguage {
        if components.scriptCode == "hant" {
            return .traditionalChinese
        }
        if components.scriptCode == "hans" {
            return .simplifiedChinese
        }

        switch components.regionCode {
        case "tw", "hk", "mo":
            return .traditionalChinese
        case "cn", "sg", nil:
            return .simplifiedChinese
        default:
            return .simplifiedChinese
        }
    }

    private static func normalizedLanguageComponents(from identifier: String) -> LanguageComponents {
        let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        let subtags = normalized.split(separator: "-").map(String.init)

        let languageCode = subtags.first
        let scriptCode = subtags.dropFirst().first(where: { Self.isScriptSubtag($0) })
        let regionCode = subtags.dropFirst().first(where: { Self.isRegionSubtag($0) })

        return LanguageComponents(
            languageCode: languageCode,
            scriptCode: scriptCode,
            regionCode: regionCode
        )
    }

    private static func isScriptSubtag(_ subtag: String) -> Bool {
        subtag.count == 4 && subtag.allSatisfy(\.isLetter)
    }

    private static func isRegionSubtag(_ subtag: String) -> Bool {
        (subtag.count == 2 && subtag.allSatisfy(\.isLetter))
            || (subtag.count == 3 && subtag.allSatisfy(\.isNumber))
    }

    private struct LanguageComponents {
        let languageCode: String?
        let scriptCode: String?
        let regionCode: String?
    }
}
