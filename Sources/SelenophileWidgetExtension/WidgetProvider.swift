import WidgetKit
import SelenophileKit

struct WidgetProvider: TimelineProvider {
    private let snapshotStore = WidgetSnapshotStore()

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: .now, snapshot: snapshotStore.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let snapshot = snapshotStore.load() ?? .placeholder
        let entry = WidgetEntry(date: .now, snapshot: snapshot)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1_800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
