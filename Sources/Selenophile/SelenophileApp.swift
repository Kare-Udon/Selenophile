import SwiftUI

@main
struct SelenophileApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appLanguageStore = AppLanguageStore.shared
    @State private var appAppearanceStore = AppAppearanceStore.shared

    var body: some Scene {
        Settings {
            EmptyView()
                .selenophileAppearance(appAppearanceStore)
        }
        .environment(\.locale, appLanguageStore.locale)
    }
}
