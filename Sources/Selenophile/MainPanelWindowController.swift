import AppKit
import SwiftUI
import SelenophileKit

@MainActor
final class MainPanelWindowController: NSWindowController {
    private static let defaultSize = NSSize(width: 494, height: 760)
    private static let minimumSize = NSSize(width: 494, height: 640)

    init(
        store: PrinterStatusStore,
        appLanguageStore: AppLanguageStore,
        onOpenSettings: @escaping () -> Void,
        onOpenLogs: @escaping () -> Void
    ) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Selenophile Debug Panel"
        window.isReleasedWhenClosed = false
        window.minSize = Self.minimumSize
        window.center()
        window.setAccessibilityTitle(window.title)

        super.init(window: window)

        window.contentViewController = NSHostingController(
            rootView: MenuContentView(
                store: store,
                appLanguageStore: appLanguageStore,
                onOpenSettings: onOpenSettings,
                onOpenLogs: onOpenLogs,
                onPreferredPopoverHeightChange: { [weak self] height in
                    self?.updatePreferredHeight(height)
                }
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func showPanel() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func updatePreferredHeight(_ height: CGFloat) {
        guard let window else { return }

        let resolvedHeight = max(Self.minimumSize.height, height)
        let currentFrame = window.frame
        let topEdge = currentFrame.maxY
        let contentSize = NSSize(width: currentFrame.width, height: resolvedHeight)
        window.setContentSize(contentSize)

        var nextFrame = window.frame
        nextFrame.origin.y = topEdge - nextFrame.height
        window.setFrame(nextFrame, display: true)
    }
}
