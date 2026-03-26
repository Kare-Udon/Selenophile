# 日志窗口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Selenophile 增加一个独立日志窗口，支持查看应用内部关键日志，并提供清空与复制能力。

**Architecture:** 在 `SelenophileKit` 内新增内存日志中心 `AppLogStore` 及日志条目类型，供业务流程写入结构化日志。应用层新增日志窗口和窗口控制器，由 `AppDelegate` 统一持有并从菜单入口打开，同时把 `PrinterStatusStore` 的关键连接、重试、相机流程接入日志埋点。

**Tech Stack:** Swift 6.2, SwiftUI, AppKit, Observation, Swift Testing, Swift Package Manager

---

### Task 1: 新增日志存储与单元测试

**Files:**
- Create: `Sources/SelenophileKit/AppLogStore.swift`
- Create: `Tests/SelenophileKitTests/AppLogStoreTests.swift`

- [ ] **Step 1: 写失败测试，覆盖追加、裁剪、清空、导出**

```swift
import Testing
@testable import SelenophileKit

@Test
func appLogStoreKeepsNewestEntriesWithinLimit() {
    let store = AppLogStore(maxEntries: 2)

    store.log(.info, source: "连接", message: "第一条")
    store.log(.error, source: "连接", message: "第二条")
    store.log(.debug, source: "连接", message: "第三条")

    #expect(store.entries.count == 2)
    #expect(store.entries[0].message == "第三条")
    #expect(store.entries[1].message == "第二条")
}

@Test
func appLogStoreClearsEntries() {
    let store = AppLogStore(maxEntries: 10)
    store.log(.info, source: "相机", message: "已加载")

    store.clear()

    #expect(store.entries.isEmpty)
}

@Test
func appLogStoreExportsReadableText() {
    let store = AppLogStore(maxEntries: 10, dateProvider: { .init(timeIntervalSince1970: 0) })
    store.log(.warning, source: "连接", message: "将在 2 秒后重试")

    let exported = store.exportText()

    #expect(exported.contains("1970-01-01 00:00:00"))
    #expect(exported.contains("[warning]"))
    #expect(exported.contains("[连接]"))
    #expect(exported.contains("将在 2 秒后重试"))
}
```

- [ ] **Step 2: 运行测试，确认 RED**

Run: `swift test --filter AppLogStoreTests`
Expected: FAIL，提示 `AppLogStore` 或相关符号不存在

- [ ] **Step 3: 写最小实现**

```swift
import Foundation
import Observation

public enum AppLogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

public struct AppLogEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: AppLogLevel
    public let source: String
    public let message: String
}

@MainActor
@Observable
public final class AppLogStore {
    public private(set) var entries: [AppLogEntry] = []

    private let maxEntries: Int
    private let dateProvider: @Sendable () -> Date

    public init(maxEntries: Int = 300, dateProvider: @escaping @Sendable () -> Date = Date.init) {
        self.maxEntries = max(1, maxEntries)
        self.dateProvider = dateProvider
    }

    public func log(_ level: AppLogLevel, source: String, message: String) {
        let entry = AppLogEntry(
            id: UUID(),
            timestamp: dateProvider(),
            level: level,
            source: source,
            message: message
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    public func clear() {
        entries.removeAll()
    }

    public func exportText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return entries.map { entry in
            "\(formatter.string(from: entry.timestamp)) [\(entry.level.rawValue)] [\(entry.source)] \(entry.message)"
        }
        .joined(separator: "\n")
    }
}
```

- [ ] **Step 4: 运行测试，确认 GREEN**

Run: `swift test --filter AppLogStoreTests`
Expected: PASS

### Task 2: 新增日志窗口与窗口控制器

**Files:**
- Create: `Sources/Selenophile/LogWindowController.swift`
- Create: `Sources/Selenophile/LogView.swift`
- Modify: `Sources/Selenophile/AppDelegate.swift`
- Modify: `Sources/Selenophile/MenuContentView.swift`
- Modify: `Sources/Selenophile/MenuBarStatusController.swift`
- Modify: `Sources/SelenophileKit/AppConfig.swift`

- [ ] **Step 1: 先写入口和标题相关测试或至少锁定 API**

```swift
// 本任务以 UI 集成为主，不增加脆弱 UI 测试。
// 先固定接口：
// - AppDelegate 持有 AppLogStore 与 LogWindowController
// - MenuContentView 新增 onOpenLogs 回调
// - MenuBarStatusController 初始化时接受 onOpenLogs
```

- [ ] **Step 2: 最小实现日志视图和窗口**

```swift
struct LogView: View {
    let logStore: AppLogStore

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("调试日志")
                Spacer()
                Button("复制全部") { /* copy */ }
                Button("清空") { logStore.clear() }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(logStore.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.message)
                            Text(entry.source)
                        }
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: 接入窗口管理和菜单入口**

Run edits in:

```swift
// AppDelegate
let logStore = AppLogStore()
private var logWindowController: LogWindowController?

func showLogWindow() {
    if let controller = logWindowController {
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        return
    }

    let controller = LogWindowController(logStore: logStore)
    logWindowController = controller
    controller.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
```

```swift
// MenuContentView / MenuBarStatusController
let onOpenLogs: () -> Void
Button("日志") { onOpenLogs() }
```

- [ ] **Step 4: 运行构建验证**

Run: `swift test --filter SelenophileTests`
Expected: PASS 或 0 tests run，但包与目标可成功编译

### Task 3: 给业务流程接入日志埋点

**Files:**
- Modify: `Sources/SelenophileKit/PrinterStatusStore.swift`
- Modify: `Sources/Selenophile/AppDelegate.swift`
- Modify: `Tests/SelenophileKitTests/PrinterStatusStoreTests.swift`

- [ ] **Step 1: 先写失败测试，证明关键事件会写入日志**

```swift
@MainActor
@Test
func saveConfigurationAndConnectionFailuresAreLogged() async {
    let logStore = AppLogStore(maxEntries: 20, dateProvider: { .init(timeIntervalSince1970: 0) })
    let client = ScriptedMoonrakerClient(eventsPerConnect: [[.failed("连接超时")]])
    let store = PrinterStatusStore(
        client: client,
        persistence: InMemoryMoonrakerConfigurationStore(),
        retryPolicy: MoonrakerRetryPolicy(maxAttempts: 1, delay: { _ in .zero }),
        sleep: { _ in },
        logStore: logStore
    )

    let success = await store.saveConfiguration(serverURLString: "http://printer.local:7125", apiToken: nil)
    #expect(success)
    try? await Task.sleep(for: .milliseconds(50))

    #expect(logStore.entries.contains(where: { $0.message.contains("配置已保存") }))
    #expect(logStore.entries.contains(where: { $0.message.contains("开始连接") }))
    #expect(logStore.entries.contains(where: { $0.message.contains("连接失败") }))
}
```

- [ ] **Step 2: 运行测试，确认 RED**

Run: `swift test --filter saveConfigurationAndConnectionFailuresAreLogged`
Expected: FAIL，提示 `PrinterStatusStore` 尚未接收 `logStore` 或未产生日志

- [ ] **Step 3: 写最小实现，把关键流程接到日志中心**

```swift
public init(
    client: MoonrakerClientProtocol = MoonrakerClient(),
    cameraClient: MoonrakerCameraClientProtocol = MoonrakerCameraClient(),
    persistence: MoonrakerConfigurationPersisting = UserDefaultsMoonrakerConfigurationStore(),
    retryPolicy: MoonrakerRetryPolicy = MoonrakerRetryPolicy(),
    sleep: @escaping @Sendable (Duration) async -> Void = { duration in
        try? await Task.sleep(for: duration)
    },
    logStore: AppLogStore? = nil
) {
    self.logStore = logStore
}
```

```swift
private func log(_ level: AppLogLevel, _ message: String) {
    logStore?.log(level, source: "PrinterStatusStore", message: message)
}
```

```swift
// 关键节点示例
log(.info, "配置已保存")
log(.info, "开始连接 Moonraker")
log(.info, "Moonraker 已连接")
log(.error, "连接失败：\(message)")
log(.warning, "将在 \(seconds) 秒后自动重试")
log(.info, "开始加载相机列表")
log(.error, "相机快照请求失败：\(error.localizedDescription)")
```

- [ ] **Step 4: 运行目标测试和相关回归测试**

Run: `swift test --filter PrinterStatusStoreTests`
Expected: PASS

### Task 4: 全量验证

**Files:**
- Modify: `docs/superpowers/plans/2026-03-26-log-window.md`

- [ ] **Step 1: 运行完整测试**

Run: `swift test`
Expected: PASS

- [ ] **Step 2: 运行可执行目标构建**

Run: `swift build`
Expected: PASS

- [ ] **Step 3: 人工检查计划覆盖情况并更新勾选**

核对项：

- 独立日志窗口存在
- 菜单中有日志入口
- 日志列表可见连接与相机相关事件
- 支持清空与复制全部
- 日志条数受上限控制

- [ ] **Step 4: 记录实际验证结果到最终汇报**

在最终汇报中明确写出运行过的命令、通过情况，以及未覆盖的残余风险。
