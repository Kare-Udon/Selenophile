import AppKit
import SwiftUI

@main
struct SelenophileApp: App {
    @State private var appLanguageStore: AppLanguageStore
    private let appDelegate: AppDelegate

    init() {
        let languageStore = AppLanguageStore()
        _appLanguageStore = State(initialValue: languageStore)
        let delegate = AppDelegate(appLanguageStore: languageStore)
        self.appDelegate = delegate
        NSApplication.shared.delegate = delegate
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .environment(\.locale, appLanguageStore.locale)
    }
}
