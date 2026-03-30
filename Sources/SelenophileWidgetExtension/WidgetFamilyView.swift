import SwiftUI
import WidgetKit
import SelenophileKit

struct WidgetFamilyView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    let snapshot: WidgetSnapshot

    var body: some View {
        WidgetCardView(snapshot: snapshot, family: widgetFamily)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 0.99),
                        Color(red: 0.89, green: 0.93, blue: 0.97)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}
