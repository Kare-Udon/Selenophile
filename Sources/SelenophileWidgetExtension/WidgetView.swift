import SwiftUI

struct WidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        WidgetFamilyView(snapshot: entry.snapshot)
    }
}
