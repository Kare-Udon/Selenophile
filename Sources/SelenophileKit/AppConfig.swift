import Foundation

public enum AppConfig {
    public static let appName = "Selenophile"
    public static let bundleIdentifier = "com.udon.selenophile"
    public static let sharedAppGroupIdentifier = "group.com.udon.selenophile"
    public static let menuTitle = "Selenophile"
    public static let projectURL = "https://github.com/udon/Selenophile"
    public static let widgetKind = "SelenophileWidget"
    public static let widgetSnapshotFileName = "widget-snapshot.json"

    public static func settingsWindowTitle(for appLanguage: AppLanguage) -> String {
        AppLocalization.localizedString(.settingsWindowTitle, language: appLanguage)
    }

    public static func logWindowTitle(for appLanguage: AppLanguage) -> String {
        AppLocalization.localizedString(.logWindowTitle, language: appLanguage)
    }

    public static func locale(for appLanguage: AppLanguage) -> Locale {
        AppLocalization.locale(for: appLanguage)
    }
}
