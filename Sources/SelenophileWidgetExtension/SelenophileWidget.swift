import WidgetKit
import SwiftUI
import SelenophileKit

@main
struct SelenophileWidgetBundle: WidgetBundle {
    var body: some Widget {
        SelenophileWidget()
    }
}

struct SelenophileWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfig.widgetKind, provider: WidgetProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Selenophile")
        .description("显示 Moonraker 打印状态。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
