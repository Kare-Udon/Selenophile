import Foundation
import Testing
@testable import SelenophileKit

@MainActor
@Test
func appLogStoreKeepsNewestEntriesWithinLimit() {
    let store = AppLogStore(maxEntries: 2)

    store.log(.info, source: "Connection", message: "First entry")
    store.log(.error, source: "Connection", message: "Second entry")
    store.log(.debug, source: "Connection", message: "Third entry")

    #expect(store.entries.count == 2)
    #expect(store.entries[0].message == "Third entry")
    #expect(store.entries[1].message == "Second entry")
}

@MainActor
@Test
func appLogStoreClearsEntries() {
    let store = AppLogStore(maxEntries: 10)
    store.log(.info, source: "Camera", message: "Loaded")

    store.clear()

    #expect(store.entries.isEmpty)
}

@MainActor
@Test
func appLogStoreExportsReadableText() {
    let store = AppLogStore(maxEntries: 10, dateProvider: { .init(timeIntervalSince1970: 0) })
    store.log(.warning, source: "Connection", message: "Retrying in 2 seconds")

    let exported = store.exportText()

    #expect(exported.contains("1970-01-01 00:00:00"))
    #expect(exported.contains("[warning]"))
    #expect(exported.contains("[Connection]"))
    #expect(exported.contains("Retrying in 2 seconds"))
}

@MainActor
@Test
func appLogStoreSanitizesNonASCIIText() {
    let store = AppLogStore(maxEntries: 10)

    store.log(.info, source: "连接", message: "连接失败")

    #expect(store.entries[0].source == "[non-ASCII text omitted]")
    #expect(store.entries[0].message == "[non-ASCII text omitted]")
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

    store.log(.debug, source: "Connection", message: "debug")
    store.log(.info, source: "Connection", message: "info")
    store.log(.warning, source: "Connection", message: "warning")
    store.log(.error, source: "Connection", message: "error")

    let filtered = store.visibleEntries(minimumLevel: .warning)

    #expect(filtered.map { $0.level } == [.error, .warning])
    #expect(filtered.map { $0.message } == ["error", "warning"])
}

@Test
func runtimeLogCallsUseEnglishTextLiterals() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources", isDirectory: true)
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(
        at: sourceRoot,
        includingPropertiesForKeys: nil
    )

    var issues: [String] = []
    while let fileURL = enumerator?.nextObject() as? URL {
        guard fileURL.pathExtension == "swift" else { continue }
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            guard line.contains("log(") || line.contains(".log(") else { continue }
            var depth = 0
            var contextLines: [String] = []
            for contextLine in lines[index..<min(index + 20, lines.count)] {
                contextLines.append(contextLine)
                depth += contextLine.reduce(0) { partial, character in
                    if character == "(" { return partial + 1 }
                    if character == ")" { return partial - 1 }
                    return partial
                }
                if depth <= 0 {
                    break
                }
            }
            let context = contextLines.joined(separator: "\n")
            if context.range(of: #"\p{Han}"#, options: .regularExpression) != nil {
                issues.append("\(fileURL.lastPathComponent):\(index + 1)")
            }
        }
    }

    #expect(
        issues.isEmpty,
        "Runtime log call sites must use English text literals: \(issues.joined(separator: ", "))"
    )
}
