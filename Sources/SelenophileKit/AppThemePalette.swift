import Foundation

public enum AppThemePalette: String, CaseIterable, Codable, Sendable {
    case `default`
    case graphite
    case github
    case tokyoNight
    case oneDark

    public static var supportedSelections: [AppThemePalette] {
        Self.allCases
    }

    public var localizationKey: AppLocalization.Key {
        switch self {
        case .default:
            return .themePaletteDefault
        case .graphite:
            return .themePaletteGraphite
        case .github:
            return .themePaletteGitHub
        case .tokyoNight:
            return .themePaletteTokyoNight
        case .oneDark:
            return .themePaletteOneDark
        }
    }
}
