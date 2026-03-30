import SwiftUI
import AppKit
import SelenophileKit

struct MenuContentView: View {
    let store: PrinterStatusStore
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    let onPreferredPopoverHeightChange: (CGFloat) -> Void
    @AppStorage("menu.cameraSnapshotCollapsed") private var isCameraSnapshotCollapsed = false
    @State private var activePreview: MenuPreview?
    @State private var baseContentHeight: CGFloat = 0
    private let cameraSnapshotImageHeight: CGFloat = 172
    private let contentPadding: CGFloat = 36
    private let cameraSnapshotSpacing: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            baseContent

            cameraSnapshotCard
                .padding(.top, isCameraSnapshotCollapsed ? 0 : cameraSnapshotSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(18)
        .frame(width: 388, alignment: .topLeading)
        .background(backgroundGradient)
        .onAppear {
            syncPopoverHeightForCurrentState()
        }
    }

    private var baseContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            staticMenuContent
            actionRow
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: MenuContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(MenuContentHeightPreferenceKey.self) { height in
            baseContentHeight = height
            syncPopoverHeightForCurrentState()
        }
    }

    private var staticMenuContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerCard
            primaryMetrics
            secondaryMetrics
            if let lastError = store.displayErrorMessage?.nonEmpty {
                errorBanner(lastError)
            }
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.969, green: 0.976, blue: 0.992),
                Color(red: 0.925, green: 0.941, blue: 0.972)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Print")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.36, green: 0.40, blue: 0.47))
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(store.printerStatus.progressText)
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.07, green: 0.10, blue: 0.15),
                                            Color(red: 1.0, green: 0.48, blue: 0.29)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(proxy.size.width * store.printerStatus.normalizedProgress, 10))
                        }
                    }
                    .frame(width: 104, height: 6)
                }

                Spacer(minLength: 10)

                thumbnailTile
            }

            HStack(alignment: .center, spacing: 10) {
                Text("任务")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.53))

                taskNameView

                Spacer(minLength: 8)

                Text(store.connectionBadgeLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(connectionBadgeForeground)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(connectionBadgeBackground)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(cardBackground)
        .popover(item: $activePreview) { preview in
            previewPopover(preview)
        }
    }

    private var primaryMetrics: some View {
        HStack(spacing: 10) {
            metricCard(
                title: "已用时间",
                value: store.printerStatus.printDuration.formattedAsClock,
                valueColor: Color.white,
                background: AnyShapeStyle(Color(red: 0.07, green: 0.10, blue: 0.15))
            )
            metricCard(
                title: "剩余时间",
                value: slicerRemainingTime.formattedAsClock,
                valueColor: Color(red: 0.15, green: 0.08, blue: 0.04),
                background: AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.48, blue: 0.29),
                            Color(red: 1.0, green: 0.64, blue: 0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
        }
    }

    private var secondaryMetrics: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            detailMetricTile("喷嘴", store.printerStatus.extruder.temperatureText)
            detailMetricTile("热床", store.printerStatus.bed.temperatureText)
            detailMetricTile("层数", store.printerStatus.layer?.layerText ?? "--")
            detailMetricTile("打印倍率", store.printerStatus.feedRateMultiplier.feedRateText)
        }
        .padding(14)
        .background(cardBackground)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(red: 0.78, green: 0.18, blue: 0.14))
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.52, green: 0.10, blue: 0.10))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(height: 44, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.99, green: 0.93, blue: 0.92))
        )
    }

    private var actionRow: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 10) {
                Button("重连") {
                    store.reconnectNow()
                }
                .buttonStyle(MenuActionButtonStyle(kind: .secondary))
                .disabled(store.connectionState == .connecting || store.connectionState == .reconnecting)

                Button("日志") {
                    onOpenLogs()
                }
                .buttonStyle(MenuActionButtonStyle(kind: .secondary))

                Button("设置") {
                    onOpenSettings()
                }
                .buttonStyle(MenuActionButtonStyle(kind: .primary))

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(MenuActionButtonStyle(kind: .ghost))
                .keyboardShortcut("q")
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button {
                    let nextCollapsed = !isCameraSnapshotCollapsed
                    isCameraSnapshotCollapsed = nextCollapsed
                    onPreferredPopoverHeightChange(nextCollapsed ? collapsedPopoverHeight : expandedPopoverHeight)
                } label: {
                    Image(systemName: isCameraSnapshotCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.28, green: 0.32, blue: 0.38))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.9), in: Capsule())
                }
                .buttonStyle(.plain)

                Button(store.isFetchingCameraSnapshot ? "抓取中…" : "刷新") {
                    Task { _ = await store.fetchCameraSnapshot() }
                }
                .buttonStyle(MenuActionButtonStyle(kind: .secondary))
                .disabled(store.isFetchingCameraSnapshot || store.configuration == nil)
            }
        }
    }

    private var cameraSnapshotCard: some View {
        cameraSnapshotCardContent
            .fixedSize(horizontal: false, vertical: true)
            .allowsHitTesting(!isCameraSnapshotCollapsed)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: isCameraSnapshotCollapsed ? 0 : cameraSnapshotExpandedHeight, alignment: .topLeading)
        .clipped()
    }

    private var cameraSnapshotCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("相机快照")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.53))
                        .textCase(.uppercase)
                        .tracking(1.6)
                }

                Spacer()
            }

            cameraSnapshotMediaContent

            if let error = store.cameraSnapshotErrorMessage?.nonEmpty {
                Text(error)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.60, green: 0.16, blue: 0.12))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(cardBackground)
    }

    private var cameraSnapshotMediaContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.93, green: 0.95, blue: 0.98))

            if let snapshotImage {
                Image(nsImage: snapshotImage)
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: store.isFetchingCameraSnapshot ? "camera.aperture" : "webcam")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
                    Text(cameraSnapshotPlaceholder)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
                }
                .padding(.horizontal, 18)
                .allowsHitTesting(false)
            }

            if store.isFetchingCameraSnapshot {
                ProgressView()
                    .controlSize(.small)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .allowsHitTesting(false)
            }
        }
        .frame(height: cameraSnapshotImageHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        }
    }

    private var snapshotImage: NSImage? {
        guard let data = store.cameraSnapshotData else { return nil }
        return NSImage(data: data)
    }

    private var cameraSnapshotExpandedHeight: CGFloat {
        let errorHeight: CGFloat = store.cameraSnapshotErrorMessage?.nonEmpty == nil ? 0 : 38
        return 226 + errorHeight
    }

    private var collapsedPopoverHeight: CGFloat {
        baseContentHeight + contentPadding
    }

    private var expandedPopoverHeight: CGFloat {
        collapsedPopoverHeight + cameraSnapshotSpacing + cameraSnapshotExpandedHeight
    }

    private func syncPopoverHeightForCurrentState() {
        guard baseContentHeight > 0 else { return }
        onPreferredPopoverHeightChange(isCameraSnapshotCollapsed ? collapsedPopoverHeight : expandedPopoverHeight)
    }

    private var cameraSnapshotPlaceholder: String {
        if store.configuration == nil {
            return "请先完成 Moonraker 配置"
        }
        if store.isFetchingCameraSnapshot {
            return "正在获取相机快照"
        }
        return "点击刷新获取一张快照"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.white.opacity(0.96))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var connectionBadgeBackground: some ShapeStyle {
        if store.isWaitingForManualReconnect {
            return AnyShapeStyle(Color(red: 0.67, green: 0.24, blue: 0.14))
        }
        switch store.connectionState {
        case .connected:
            return AnyShapeStyle(Color(red: 0.07, green: 0.10, blue: 0.15))
        case .connecting, .reconnecting:
            return AnyShapeStyle(Color(red: 0.18, green: 0.36, blue: 0.66))
        case .failed, .disconnected:
            return AnyShapeStyle(Color(red: 0.78, green: 0.18, blue: 0.14))
        case .unconfigured:
            return AnyShapeStyle(Color.black.opacity(0.12))
        }
    }

    private var connectionBadgeForeground: Color {
        store.connectionState == .unconfigured ? Color(red: 0.32, green: 0.36, blue: 0.42) : .white
    }

    private var thumbnailImage: NSImage? {
        guard let data = store.currentPrintThumbnailData else { return nil }
        return NSImage(data: data)
    }

    private var thumbnailTile: some View {
        Group {
            if thumbnailImage != nil {
                Button {
                    activePreview = .thumbnail
                } label: {
                    thumbnailTileBody
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看打印缩略图")
            } else if store.canManuallyRetryCurrentPrintThumbnail {
                Button {
                    store.retryCurrentPrintThumbnail()
                } label: {
                    thumbnailTileBody
                }
                .buttonStyle(.plain)
            } else {
                thumbnailTileBody
            }
        }
    }

    private var taskNameView: some View {
        Group {
            if let filename = store.printerStatus.filename {
                Button {
                    activePreview = .taskName(filename)
                } label: {
                    Text(filename)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("查看任务全名")
            } else {
                Text("当前无打印任务")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    private var thumbnailTileBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.95, green: 0.96, blue: 0.98))

            if let thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: store.isFetchingCurrentPrintThumbnail ? "photo" : "square.stack.3d.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
                    Text(thumbnailPlaceholderText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
                }
                .padding(8)
            }

            if store.isFetchingCurrentPrintThumbnail {
                ProgressView()
                    .controlSize(.mini)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
        }
        .frame(width: 86, height: 86)
    }

    private var thumbnailPlaceholderText: String {
        if store.isFetchingCurrentPrintThumbnail {
            return "缩略图"
        }
        if store.isWaitingForManualCurrentPrintThumbnailRetry || store.currentPrintThumbnailErrorMessage != nil {
            return "点击重试"
        }
        return "无缩略图"
    }

    @ViewBuilder
    private func previewPopover(_ preview: MenuPreview) -> some View {
        switch preview {
        case .thumbnail:
            VStack(alignment: .leading, spacing: 12) {
                Text("打印缩略图")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))

                if let thumbnailImage {
                    Image(nsImage: thumbnailImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(maxWidth: 360, maxHeight: 360)
                        .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Text("当前没有可预览的打印缩略图")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.43, blue: 0.50))
                }
            }
            .padding(16)
            .frame(width: 384, alignment: .leading)

        case .taskName(let fullName):
            VStack(alignment: .leading, spacing: 12) {
                Text("任务全名")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.07, green: 0.10, blue: 0.15))

                Text(fullName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.14, green: 0.17, blue: 0.22))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                Text("可直接选中文本复制")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.53))
            }
            .padding(16)
            .frame(width: 320, alignment: .leading)
        }
    }

    private func metricCard(
        title: String,
        value: String,
        valueColor: Color,
        background: AnyShapeStyle
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(valueColor.opacity(0.66))
            Text(value)
                .font(.system(size: 21, weight: .bold, design: .monospaced))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(background)
        )
    }

    private func detailMetricTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.53))

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.14, green: 0.17, blue: 0.22))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.965, green: 0.972, blue: 0.984))
        )
    }

    private var slicerRemainingTime: TimeInterval? {
        guard let printDuration = store.printerStatus.printDuration else {
            return store.printerStatus.estimatedTimeRemaining
        }
        guard let slicerEstimatedPrintTime = store.printerStatus.slicerEstimatedPrintTime else {
            return store.printerStatus.estimatedTimeRemaining
        }
        return max(0, slicerEstimatedPrintTime - printDuration)
    }
}

private enum MenuPreview: Identifiable {
    case thumbnail
    case taskName(String)

    var id: String {
        switch self {
        case .thumbnail:
            return "thumbnail"
        case .taskName(let name):
            return "taskName:\(name)"
        }
    }
}

private struct MenuActionButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case ghost
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(background(configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            return .white
        case .secondary:
            return Color(red: 0.07, green: 0.10, blue: 0.15)
        case .ghost:
            return Color(red: 0.25, green: 0.29, blue: 0.35)
        }
    }

    private func background(_ isPressed: Bool) -> AnyView {
        switch kind {
        case .primary:
            return AnyView(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isPressed ? Color(red: 0.04, green: 0.07, blue: 0.12) : Color(red: 0.07, green: 0.10, blue: 0.15))
            )
        case .secondary:
            return AnyView(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isPressed ? Color.white.opacity(0.72) : Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
            )
        case .ghost:
            return AnyView(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isPressed ? Color.black.opacity(0.12) : Color.black.opacity(0.07))
            )
        }
    }
}

private extension Date {
    var menuTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: self)
    }
}

private extension PrinterStatus {
    var progressText: String {
        guard let progress else { return "--" }
        return "\(Int((progress * 100).rounded()))%"
    }
}

private extension Optional where Wrapped == TimeInterval {
    var formattedAsClock: String {
        guard let self else { return "--" }
        let totalSeconds = Int(self.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private extension Optional where Wrapped == TemperatureStatus {
    var temperatureText: String {
        guard let self else { return "--" }
        return String(format: "%.1f / %.1f °C", self.actual, self.target)
    }
}

private extension Optional where Wrapped == Double {
    var feedRateText: String {
        guard let self else { return "--" }
        return "\(Int((self * 100).rounded()))%"
    }
}

private extension LayerStatus {
    var layerText: String {
        if let total {
            return "\(current) / \(total)"
        }
        return "\(current)"
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct MenuContentHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
