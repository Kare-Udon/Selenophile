import Foundation
import Testing
@testable import SelenophileKit

@MainActor
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

@MainActor
@Test
func appLogStoreClearsEntries() {
    let store = AppLogStore(maxEntries: 10)
    store.log(.info, source: "相机", message: "已加载")

    store.clear()

    #expect(store.entries.isEmpty)
}

@MainActor
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

@Test
func appLogLevelOrdersBySeverity() {
    #expect(AppLogLevel.debug < AppLogLevel.info)
    #expect(AppLogLevel.info < AppLogLevel.warning)
    #expect(AppLogLevel.warning < AppLogLevel.error)
}

@MainActor
@Test
func appLogStoreFiltersEntriesByMinimumLevel() {
    let store = AppLogStore(maxEntries: 10)

    store.log(.debug, source: "连接", message: "debug")
    store.log(.info, source: "连接", message: "info")
    store.log(.warning, source: "连接", message: "warning")
    store.log(.error, source: "连接", message: "error")

    let filtered = store.visibleEntries(minimumLevel: .warning)

    #expect(filtered.map { $0.level } == [.error, .warning])
    #expect(filtered.map { $0.message } == ["error", "warning"])
}
