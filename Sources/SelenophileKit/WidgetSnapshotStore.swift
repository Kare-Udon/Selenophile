import Foundation

public final class WidgetSnapshotStore {
    let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileManager: FileManager = .default,
        containerURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        let resolvedContainerURL = containerURL
            ?? fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.sharedAppGroupIdentifier)
            ?? fileManager.temporaryDirectory.appendingPathComponent("SelenophileWidget", isDirectory: true)

        self.fileURL = resolvedContainerURL.appendingPathComponent(AppConfig.widgetSnapshotFileName)
    }

    public func load() -> WidgetSnapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    public func save(_ snapshot: WidgetSnapshot) {
        do {
            try fileManager.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
    }

    public func clear() {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try? fileManager.removeItem(at: fileURL)
    }
}
