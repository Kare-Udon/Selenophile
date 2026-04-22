import AppKit
import Observation
import SwiftUI
import WidgetKit
import SelenophileKit

protocol WidgetTimelineReloading {
    func reloadTimelines(ofKind kind: String)
}

extension WidgetCenter: WidgetTimelineReloading {}

@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let logStore: AppLogStore
    let store: PrinterStatusStore
    let launchAtLoginController: LaunchAtLoginController
    let appLanguageStore: AppLanguageStore
    private let widgetSnapshotStore: WidgetSnapshotStore
    private let widgetCenter: any WidgetTimelineReloading
    private var settingsWindowController: NSWindowController?
    private var logWindowController: LogWindowController?
    private var menuBarStatusController: MenuBarStatusController?

    convenience override init() {
        self.init(logStore: AppLogStore(), appLanguageStore: AppLanguageStore.shared)
    }

    init(
        logStore: AppLogStore? = nil,
        store: PrinterStatusStore? = nil,
        launchAtLoginController: LaunchAtLoginController = LaunchAtLoginController(),
        appLanguageStore: AppLanguageStore = AppLanguageStore.shared,
        widgetSnapshotStore: WidgetSnapshotStore = WidgetSnapshotStore(),
        widgetCenter: any WidgetTimelineReloading = WidgetCenter.shared
    ) {
        let resolvedLogStore = logStore ?? AppLogStore()
        let resolvedStore = store ?? PrinterStatusStore(logStore: resolvedLogStore)
        self.logStore = resolvedLogStore
        self.store = resolvedStore
        self.launchAtLoginController = launchAtLoginController
        self.appLanguageStore = appLanguageStore
        self.widgetSnapshotStore = widgetSnapshotStore
        self.widgetCenter = widgetCenter
        super.init()
        self.store.onWidgetSnapshotChange = { [weak self] snapshot in
            self?.publishWidgetSnapshot(snapshot)
        }
        self.store.onConfigurationChange = { [weak self] configuration in
            self?.appLanguageStore.update(selectedLanguage: configuration?.appLanguage)
            self?.refreshLocalizedWindowTitles()
        }
        self.appLanguageStore.update(selectedLanguage: self.store.configuration?.appLanguage)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logStore.log(.info, source: "AppDelegate", message: "应用已启动")
        menuBarStatusController = MenuBarStatusController(
            store: store,
            appLanguageStore: appLanguageStore,
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
            window.title = settingsWindowTitle()
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 840, height: 580),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = settingsWindowTitle()
        window.isReleasedWhenClosed = false
        window.delegate = self
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
            window.title = logWindowTitle()
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let controller = LogWindowController(logStore: logStore, appLanguageStore: appLanguageStore)
        controller.window?.title = logWindowTitle()
        logWindowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func closeSettingsWindow() {
        settingsWindowController?.close()
    }

    func previewLanguageSelection(_ language: AppLanguage) {
        appLanguageStore.update(selectedLanguage: language)
        refreshLocalizedWindowTitles()
    }

    func restorePersistedLanguageSelection() {
        appLanguageStore.update(selectedLanguage: store.configuration?.appLanguage)
        refreshLocalizedWindowTitles()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        guard window === settingsWindowController?.window else { return }
        restorePersistedLanguageSelection()
    }

    private func publishWidgetSnapshot(_ snapshot: WidgetSnapshot) {
        widgetSnapshotStore.save(snapshot)
        widgetCenter.reloadTimelines(ofKind: AppConfig.widgetKind)
    }

    func settingsWindowTitle() -> String {
        AppConfig.settingsWindowTitle(for: appLanguageStore.effectiveLanguage())
    }

    func logWindowTitle() -> String {
        AppConfig.logWindowTitle(for: appLanguageStore.effectiveLanguage())
    }

    private func refreshLocalizedWindowTitles() {
        settingsWindowController?.window?.title = settingsWindowTitle()
        logWindowController?.window?.title = logWindowTitle()
    }

    private func makeSettingsView() -> some View {
        SettingsView(
            store: store,
            onClose: { [weak self] in
                self?.closeSettingsWindow()
            },
            onCancel: { [weak self] in
                self?.restorePersistedLanguageSelection()
                self?.closeSettingsWindow()
            },
            onLanguageSelectionPreview: { [weak self] language in
                self?.previewLanguageSelection(language)
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
            ),
            appLanguageStore: appLanguageStore
        )
        .environment(\.locale, appLanguageStore.locale)
    }
}
