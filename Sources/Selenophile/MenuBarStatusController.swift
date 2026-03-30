import AppKit
import Observation
import SwiftUI
import SelenophileKit

@MainActor
final class MenuBarStatusController: NSObject {
    private static let popoverWidth: CGFloat = 388
    private static let popoverHeight: CGFloat = 640

    private let store: PrinterStatusStore
    private let onOpenSettings: () -> Void
    private let onOpenLogs: () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let iconRenderer = MenuBarStatusIconRenderer()
    private var hostingController: NSHostingController<MenuContentView>?

    init(
        store: PrinterStatusStore,
        onOpenSettings: @escaping () -> Void,
        onOpenLogs: @escaping () -> Void
    ) {
        self.store = store
        self.onOpenSettings = onOpenSettings
        self.onOpenLogs = onOpenLogs
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        configurePopover()
        refreshStatusItem()
        beginObservingStore()
    }

    func tearDown() {
        popover.performClose(nil)
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        let hostingController = NSHostingController(
            rootView: MenuContentView(
                store: store,
                onOpenSettings: onOpenSettings,
                onOpenLogs: onOpenLogs,
                onPreferredPopoverHeightChange: { [weak self] height in
                    self?.updatePopoverHeight(height)
                }
            )
        )
        self.hostingController = hostingController
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: Self.popoverWidth, height: Self.popoverHeight)
    }

    private func updatePopoverHeight(_ height: CGFloat) {
        let resolvedHeight = max(0, height)
        let newSize = NSSize(width: Self.popoverWidth, height: resolvedHeight)
        guard popover.contentSize != newSize else { return }

        let topEdge = popover.contentViewController?.view.window?.frame.maxY
        popover.contentSize = newSize

        guard let topEdge, let window = popover.contentViewController?.view.window else { return }
        var frame = window.frame
        frame.origin.y = topEdge - frame.height
        window.setFrame(frame, display: true)
    }

    private func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        let configuration = MenuBarIconConfiguration(
            connectionState: store.connectionState,
            isWaitingForManualReconnect: store.isWaitingForManualReconnect,
            hasActivePrint: store.hasActivePrint,
            progress: store.printerStatus.normalizedProgress
        )
        button.image = iconRenderer.makeImage(configuration: configuration)
        button.imageScaling = .scaleProportionallyDown
        button.contentTintColor = nil
        button.toolTip = tooltipText
    }

    private var tooltipText: String {
        let progressText = formattedProgressText(for: store.printerStatus.progress)
        let stateText = store.printerStatus.state.localizedLabel
        return "Selenophile\n状态：\(stateText)\n进度：\(progressText)"
    }

    private func beginObservingStore() {
        withObservationTracking {
            _ = store.connectionState
            _ = store.isWaitingForManualReconnect
            _ = store.hasActivePrint
            _ = store.printerStatus
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshStatusItem()
                self?.beginObservingStore()
            }
        }
    }

    private func formattedProgressText(for progress: Double?) -> String {
        guard let progress else { return "--" }
        return "\(Int((progress * 100).rounded()))%"
    }
}
