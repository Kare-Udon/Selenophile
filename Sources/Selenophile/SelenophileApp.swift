import SwiftUI

@main
struct SelenophileApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appLanguageStore = AppLanguageStore.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .environment(\.locale, appLanguageStore.locale)
    }
}
