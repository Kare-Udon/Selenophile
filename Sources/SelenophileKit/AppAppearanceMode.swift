import Foundation

public enum AppAppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark

    public static var supportedSelections: [AppAppearanceMode] {
        Self.allCases
    }

    public var localizationKey: AppLocalization.Key {
        switch self {
        case .system:
            return .followSystem
        case .light:
            return .appearanceLightMode
        case .dark:
            return .appearanceDarkMode
        }
    }
}
