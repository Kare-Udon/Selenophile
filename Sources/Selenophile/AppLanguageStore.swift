import Foundation
import Observation
import SelenophileKit

@MainActor
@Observable
final class AppLanguageStore {
    var selectedLanguage: AppLanguage

    init(selectedLanguage: AppLanguage = .system) {
        self.selectedLanguage = selectedLanguage
    }

    func update(selectedLanguage: AppLanguage?) {
        self.selectedLanguage = selectedLanguage ?? .system
    }

    func effectiveLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        selectedLanguage.resolved(preferredLanguages: preferredLanguages)
    }

    func resolvedLocale(preferredLanguages: [String] = Locale.preferredLanguages) -> Locale {
        AppConfig.locale(for: effectiveLanguage(preferredLanguages: preferredLanguages))
    }

    var locale: Locale {
        resolvedLocale(preferredLanguages: Locale.preferredLanguages)
    }
}
