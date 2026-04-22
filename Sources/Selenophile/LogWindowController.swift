import AppKit
import SwiftUI
import SelenophileKit

@MainActor
final class LogWindowController: NSWindowController {
    init(logStore: AppLogStore, appLanguageStore: AppLanguageStore) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 520),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppConfig.logWindowTitle(for: appLanguageStore.effectiveLanguage())
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = NSHostingController(
            rootView: LogView(logStore: logStore, appLanguageStore: appLanguageStore)
        )

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
