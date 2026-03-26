import AppKit
import SwiftUI
import SelenophileKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let logStore: AppLogStore
    let store: PrinterStatusStore
    private var settingsWindowController: NSWindowController?
    private var logWindowController: LogWindowController?
    private var menuBarStatusController: MenuBarStatusController?

    override init() {
        let logStore = AppLogStore()
        self.logStore = logStore
        self.store = PrinterStatusStore(logStore: logStore)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logStore.log(.info, source: "AppDelegate", message: "应用已启动")
        menuBarStatusController = MenuBarStatusController(
            store: store,
            onOpenSettings: { [weak self] in
                self?.showSettingsWindow()
            },
            onOpenLogs: { [weak self] in
                self?.showLogWindow()
            }
        )

        if store.needsInitialConfiguration {
            logStore.log(.info, source: "AppDelegate", message: "检测到未配置 Moonraker，打开设置窗口")
            showSettingsWindow()
        } else {
            store.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarStatusController?.tearDown()
    }

    func showSettingsWindow() {
        logStore.log(.debug, source: "AppDelegate", message: "打开设置窗口")
        let settingsView = SettingsView(store: store) { [weak self] in
            self?.closeSettingsWindow()
        }

        if let window = settingsWindowController?.window {
            window.contentViewController = NSHostingController(rootView: settingsView)
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppConfig.settingsWindowTitle
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = NSHostingController(rootView: settingsView)
        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func showLogWindow() {
        logStore.log(.debug, source: "AppDelegate", message: "打开日志窗口")
        if let window = logWindowController?.window {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let controller = LogWindowController(logStore: logStore)
        logWindowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func closeSettingsWindow() {
        settingsWindowController?.close()
    }
}
