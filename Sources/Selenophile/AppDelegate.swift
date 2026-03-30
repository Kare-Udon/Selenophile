import AppKit
import SwiftUI
import WidgetKit
import SelenophileKit

protocol WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String)
}

extension WidgetCenter: WidgetTimelineReloading {}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let logStore: AppLogStore
    let store: PrinterStatusStore
    let launchAtLoginController: LaunchAtLoginController
    private let widgetSnapshotStore: WidgetSnapshotStore
    private let widgetCenter: any WidgetTimelineReloading
    private var settingsWindowController: NSWindowController?
    private var logWindowController: LogWindowController?
    private var menuBarStatusController: MenuBarStatusController?

    convenience override init() {
        self.init(logStore: AppLogStore())
    }

    init(
        logStore: AppLogStore? = nil,
        store: PrinterStatusStore? = nil,
        launchAtLoginController: LaunchAtLoginController = LaunchAtLoginController(),
        widgetSnapshotStore: WidgetSnapshotStore = WidgetSnapshotStore(),
        widgetCenter: any WidgetTimelineReloading = WidgetCenter.shared
    ) {
        let resolvedLogStore = logStore ?? AppLogStore()
        self.logStore = resolvedLogStore
        self.store = store ?? PrinterStatusStore(logStore: resolvedLogStore)
        self.launchAtLoginController = launchAtLoginController
        self.widgetSnapshotStore = widgetSnapshotStore
        self.widgetCenter = widgetCenter
        super.init()
        self.store.onWidgetSnapshotChange = { [weak self] snapshot in
            self?.publishWidgetSnapshot(snapshot)
        }
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

        publishWidgetSnapshot(store.widgetSnapshot())

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
        let settingsView = makeSettingsView()

        if let window = settingsWindowController?.window {
            window.contentViewController = NSHostingController(rootView: settingsView)
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 460),
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

    private func publishWidgetSnapshot(_ snapshot: WidgetSnapshot) {
        widgetSnapshotStore.save(snapshot)
        widgetCenter.reloadTimelines(ofKind: AppConfig.widgetKind)
    }

    private func makeSettingsView() -> SettingsView {
        SettingsView(
            store: store,
            onClose: { [weak self] in
                self?.closeSettingsWindow()
            },
            launchAtLoginControl: .init(
                isAvailable: true,
                isEnabled: { [weak self] in
                    self?.launchAtLoginController.isEnabled ?? false
                },
                setIsEnabled: { [weak self] enabled in
                    guard let self else { return }
                    do {
                        try self.launchAtLoginController.setEnabled(enabled)
                    } catch {
                        self.logStore.log(
                            .error,
                            source: "LaunchAtLogin",
                            message: "更新开机自启失败：\(error.localizedDescription)"
                        )
                    }
                }
            )
        )
    }
}
