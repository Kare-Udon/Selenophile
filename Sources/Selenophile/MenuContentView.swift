import AppKit
import SwiftUI
import SelenophileKit

struct MenuContentView: View {
    static let preferredWidth: CGFloat = 445
    static let preferredHeight: CGFloat = 684
    static let minimumHeight: CGFloat = 576

    let store: PrinterStatusStore
    let appLanguageStore: AppLanguageStore
    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void
    let onPreferredPopoverHeightChange: (CGFloat) -> Void

    @AppStorage("menu.cameraSnapshotCollapsed") private var isCameraSnapshotCollapsed = false
    @State private var activePreview: MenuPreview?
    @State private var baseContentHeight: CGFloat = 0
    @State private var hoveredActionHint: String?
    @State private var hoverHintTask: Task<Void, Never>?

    private let cameraSnapshotFallbackAspectRatio: CGFloat = 16.0 / 9.0
    private let outerPadding: CGFloat = 14
    private let contentPadding: CGFloat = 25
    private let cameraSnapshotSpacing: CGFloat = 8
    private let cameraSnapshotMaximumMediaHeight: CGFloat = 160
    private let thumbnailTopSpacing: CGFloat = 22

    private var uiLanguage: AppLanguage {
        appLanguageStore.selectedLanguage.resolved(preferredLanguages: Locale.preferredLanguages)
    }

    private func l10n(_ key: AppLocalization.Key) -> String {
        AppLocalization.localizedString(key, language: uiLanguage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            baseContent

            cameraSnapshotCard
                .padding(.top, cameraSnapshotSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(outerPadding)
        .frame(width: Self.preferredWidth, alignment: .topLeading)
        .background {
            SelenophileWindowBackground()
        }
        .onAppear {
            syncPopoverHeightForCurrentState()
        }
    }

    private var baseContent: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        VStack(alignment: .leading, spacing: 10) {
            headerCard
            timeCards
            detailMetrics
            if let lastError = store.displayErrorMessage?.nonEmpty {
                errorBanner(lastError)
            }
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    SelenophileSectionLabel(text: l10n(.menuLivePrint))

                    Text(store.printerStatus.progressText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.primaryText)

                    progressBar
                        .frame(height: 6)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(l10n(.menuTask))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                            .textCase(.uppercase)
                            .tracking(1.2)

                        taskNameView
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                VStack(alignment: .trailing, spacing: 0) {
                    connectionBadge
                        .padding(.bottom, thumbnailTopSpacing)
                    thumbnailTile
                }
                .frame(width: 112, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .selenophileCard()
        .popover(item: $activePreview) { preview in
            previewPopover(preview)
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(SelenophileTheme.Colors.divider)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                SelenophileTheme.Colors.accent,
                                SelenophileTheme.Colors.secondaryAccent
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(proxy.size.width * store.printerStatus.normalizedProgress, 14))
            }
        }
    }

    private var connectionBadge: some View {
        SelenophileStatusBadge(
            text: store.connectionBadgeLabel.uppercased(),
            foreground: connectionBadgeForeground,
            background: connectionBadgeBackground
        )
    }

    private var timeCards: some View {
        HStack(spacing: 9) {
            summaryMetricCard(
                title: l10n(.menuElapsedTime),
                value: store.printerStatus.printDuration.formattedAsClock,
                symbol: "clock",
                accent: SelenophileTheme.Colors.warning,
                emphasized: false
            )

            summaryMetricCard(
                title: l10n(.menuRemainingTime),
                value: slicerRemainingTime.formattedAsClock,
                symbol: "hourglass",
                accent: SelenophileTheme.Colors.accent,
                emphasized: true
            )
        }
    }

    private func summaryMetricCard(
        title: String,
        value: String,
        symbol: String,
        accent: Color,
        emphasized: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 23, height: 23)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.0)

                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(emphasized ? accent : SelenophileTheme.Colors.primaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
        .selenophileCard(fill: SelenophileTheme.Colors.surfaceRaised)
    }

    private var detailMetrics: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 4),
            spacing: 7
        ) {
            detailMetricTile(symbol: "thermometer.medium", title: l10n(.menuNozzle), value: store.printerStatus.extruder.temperatureText)
            detailMetricTile(symbol: "heat.waves", title: l10n(.menuBed), value: store.printerStatus.bed.temperatureText)
            detailMetricTile(symbol: "square.stack.3d.up", title: l10n(.menuLayer), value: store.printerStatus.layer?.layerText ?? "--")
            detailMetricTile(symbol: "gauge.with.dots.needle.100percent", title: l10n(.menuPrintSpeed), value: store.printerStatus.feedRateMultiplier.feedRateText)
        }
    }

    private func detailMetricTile(symbol: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SelenophileTheme.Colors.accent)
                    .frame(width: 16, height: 16)

                Text(title)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                    .textCase(.uppercase)
                    .tracking(0.9)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.48)
                .allowsTightening(true)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
        .selenophileCard(
            cornerRadius: SelenophileTheme.Metrics.mediumCorner,
            fill: SelenophileTheme.Colors.surfaceRaised
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SelenophileTheme.Colors.danger)

            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SelenophileTheme.Colors.primaryText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .selenophileCard(
            cornerRadius: SelenophileTheme.Metrics.mediumCorner,
            fill: SelenophileTheme.Colors.danger.opacity(0.15),
            strokeOpacity: 0.45
        )
    }

    private var actionRow: some View {
        HStack(spacing: 9) {
            HStack(spacing: 8) {
                labeledActionButton(systemName: "arrow.clockwise", title: l10n(.menuReconnect)) {
                    store.reconnectNow()
                }
                .disabled(store.connectionState == .connecting || store.connectionState == .reconnecting)

                labeledActionButton(systemName: "text.alignleft", title: l10n(.menuOpenLogs)) {
                    onOpenLogs()
                }
            }

            Spacer(minLength: 6)

            HStack(spacing: 7) {
                iconActionButton(systemName: "gearshape", title: l10n(.menuOpenSettings), kind: .secondary) {
                    onOpenSettings()
                }

                Rectangle()
                    .fill(SelenophileTheme.Colors.divider)
                    .frame(width: 1, height: 27)
                    .padding(.horizontal, 1)

                iconActionButton(systemName: "power", title: l10n(.menuQuit), kind: .destructive) {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }

    private func labeledActionButton(
        systemName: String,
        title: String,
        kind: SelenophileButtonStyle.Kind = .secondary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 18, height: 18)
                    .background(
                        Circle()
                            .fill(SelenophileTheme.Colors.controlPressed)
                    )

                Text(title)
                    .lineLimit(1)
            }
            .frame(height: 18)
        }
        .buttonStyle(SelenophileButtonStyle(kind: kind, scale: 0.9))
    }

    private func iconActionButton(
        systemName: String,
        title: String,
        kind: SelenophileButtonStyle.Kind,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 16, height: 16)
        }
        .buttonStyle(SelenophileButtonStyle(kind: kind, compact: true, scale: 0.9))
        .menuToolTip(title)
        .accessibilityLabel(title)
        .overlay(alignment: .top) {
            if hoveredActionHint == title {
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(SelenophileTheme.Colors.surfaceMuted.opacity(0.98))
                    )
                    .offset(y: -27)
                    .fixedSize()
                    .allowsHitTesting(false)
            }
        }
        .zIndex(hoveredActionHint == title ? 1 : 0)
        .onHover { isHovered in
            updateHoveredActionHint(isHovered ? title : nil)
        }
    }

    private func updateHoveredActionHint(_ hint: String?) {
        hoverHintTask?.cancel()

        guard let hint else {
            hoveredActionHint = nil
            return
        }

        hoverHintTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            hoveredActionHint = hint
        }
    }

    private var cameraSnapshotCard: some View {
        cameraSnapshotCardContent
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var cameraSnapshotCardContent: some View {
        VStack(alignment: .leading, spacing: isCameraSnapshotCollapsed ? 0 : 9) {
            HStack(alignment: .center) {
                Label {
                    SelenophileSectionLabel(text: l10n(.menuCameraSnapshot))
                } icon: {
                    Image(systemName: "camera")
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                }

                Spacer(minLength: 10)

                HStack(spacing: isCameraSnapshotCollapsed ? 0 : 7) {
                    if !isCameraSnapshotCollapsed {
                        Button(store.isFetchingCameraSnapshot ? l10n(.menuRefreshing) : l10n(.menuRefresh)) {
                            Task { _ = await store.fetchCameraSnapshot() }
                        }
                        .buttonStyle(SelenophileButtonStyle(kind: .secondary, scale: 0.9))
                        .frame(width: 56)
                        .contentShape(RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous))
                        .disabled(store.isFetchingCameraSnapshot || store.configuration == nil)
                    }

                    Button {
                        let nextCollapsed = !isCameraSnapshotCollapsed
                        isCameraSnapshotCollapsed = nextCollapsed
                        onPreferredPopoverHeightChange(nextCollapsed ? collapsedPopoverHeight : expandedPopoverHeight)
                    } label: {
                        Image(systemName: isCameraSnapshotCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 31, height: 31)
                    }
                    .buttonStyle(SelenophileButtonStyle(kind: .secondary, compact: true, scale: 0.9))
                    .contentShape(RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous))
                    .accessibilityLabel(l10n(.menuCameraSnapshot))
                }
                .zIndex(2)
            }

            if !isCameraSnapshotCollapsed {
                cameraSnapshotMediaContent

                if let snapshotUpdatedLabel {
                    HStack {
                        Text(snapshotUpdatedLabel)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(SelenophileTheme.Colors.secondaryText)

                        Spacer(minLength: 9)
                    }
                }

                if let error = store.cameraSnapshotErrorMessage?.nonEmpty {
                    Text(error)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, isCameraSnapshotCollapsed ? 11 : 14)
        .padding(.vertical, isCameraSnapshotCollapsed ? 7 : 12)
        .selenophileCard()
    }

    private var cameraSnapshotMediaContent: some View {
        Group {
            if isCameraSnapshotCollapsed {
                EmptyView()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.mediumCorner, style: .continuous)
                        .fill(SelenophileTheme.Colors.surfaceMuted)

                    if let snapshotImage {
                        Image(nsImage: snapshotImage)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(snapshotAspectRatio, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                    } else {
                        VStack(spacing: 9) {
                            Image(systemName: store.isFetchingCameraSnapshot ? "camera.aperture" : "webcam")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(SelenophileTheme.Colors.secondaryText)

                            Text(cameraSnapshotPlaceholder)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                        }
                        .padding(.horizontal, 16)
                        .allowsHitTesting(false)
                    }

                    if store.isFetchingCameraSnapshot {
                        ProgressView()
                            .controlSize(.small)
                            .padding(9)
                            .background(.ultraThinMaterial, in: Capsule())
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: cameraSnapshotMediaHeight)
                .clipShape(RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.mediumCorner, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.mediumCorner, style: .continuous)
                        .stroke(SelenophileTheme.Colors.border, lineWidth: 1)
                }
            }
        }
    }

    private var snapshotUpdatedLabel: String? {
        guard let updatedAt = store.cameraSnapshotUpdatedAt else {
            return nil
        }
        return "\(l10n(.menuLastUpdatedPrefix)): \(updatedAt.menuTimestamp)"
    }

    private var snapshotImage: NSImage? {
        guard let data = store.cameraSnapshotData else { return nil }
        return NSImage(data: data)
    }

    private var snapshotAspectRatio: CGFloat {
        guard let snapshotImage else {
            return cameraSnapshotFallbackAspectRatio
        }

        let size = snapshotImage.size
        guard size.width > 0, size.height > 0 else {
            return cameraSnapshotFallbackAspectRatio
        }

        return size.width / size.height
    }

    private var cameraSnapshotExpandedHeight: CGFloat {
        let errorHeight: CGFloat = store.cameraSnapshotErrorMessage?.nonEmpty == nil ? 0 : 34
        let footerHeight: CGFloat = store.cameraSnapshotUpdatedAt == nil ? 0 : 18
        let imageHeight = cameraSnapshotMediaHeight
        return 67 + imageHeight + footerHeight + errorHeight
    }

    private var cameraSnapshotMediaHeight: CGFloat {
        min(availableContentWidth / snapshotAspectRatio, cameraSnapshotMaximumMediaHeight)
    }

    private var cameraSnapshotCollapsedHeight: CGFloat {
        45
    }

    private var collapsedPopoverHeight: CGFloat {
        baseContentHeight + cameraSnapshotSpacing + cameraSnapshotCollapsedHeight + contentPadding
    }

    private var expandedPopoverHeight: CGFloat {
        baseContentHeight + cameraSnapshotSpacing + cameraSnapshotExpandedHeight + contentPadding
    }

    private var availableContentWidth: CGFloat {
        Self.preferredWidth - (outerPadding * 2) - (14 * 2)
    }

    private func syncPopoverHeightForCurrentState() {
        guard baseContentHeight > 0 else { return }
        onPreferredPopoverHeightChange(isCameraSnapshotCollapsed ? collapsedPopoverHeight : expandedPopoverHeight)
    }

    private var cameraSnapshotPlaceholder: String {
        if store.configuration == nil {
            return l10n(.menuNeedConfigForCameraSnapshot)
        }
        if store.isFetchingCameraSnapshot {
            return l10n(.menuFetchingCameraSnapshot)
        }
        return l10n(.menuRefreshToGetSnapshot)
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
                .accessibilityLabel(l10n(.menuViewThumbnailAccessibility))
            } else if store.canManuallyRetryCurrentPrintThumbnail {
                Button {
                    store.retryCurrentPrintThumbnail()
                } label: {
                    thumbnailTileBody
                }
                .buttonStyle(.plain)
                .accessibilityLabel(l10n(.menuThumbnailPlaceholderRetry))
            } else {
                thumbnailTileBody
            }
        }
    }

    private var thumbnailTileBody: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.mediumCorner, style: .continuous)
                .fill(SelenophileTheme.Colors.surfaceRaised)

            if let thumbnailImage {
                Image(nsImage: thumbnailImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: store.isFetchingCurrentPrintThumbnail ? "photo" : "cube.transparent")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)

                    Text(thumbnailPlaceholderText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                }
                .padding(9)
            }

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                .padding(6)
                .background(Color.black.opacity(0.30), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(7)

            if store.isFetchingCurrentPrintThumbnail {
                ProgressView()
                    .controlSize(.mini)
                    .padding(7)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.mediumCorner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.mediumCorner, style: .continuous)
                .stroke(SelenophileTheme.Colors.border, lineWidth: 1)
        }
        .frame(width: 108, height: 84)
    }

    private var thumbnailPlaceholderText: String {
        if store.isFetchingCurrentPrintThumbnail {
            return l10n(.menuThumbnailPlaceholderFetching)
        }
        if store.isWaitingForManualCurrentPrintThumbnailRetry || store.currentPrintThumbnailErrorMessage != nil {
            return l10n(.menuThumbnailPlaceholderRetry)
        }
        return l10n(.menuThumbnailPlaceholderEmpty)
    }

    private var taskNameView: some View {
        Group {
            if let filename = store.printerStatus.filename {
                Button {
                    activePreview = .taskName(filename)
                } label: {
                    Text(filename)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(l10n(.menuViewTaskNameAccessibility))
            } else {
                Text(l10n(.menuNoPrintTask))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func previewPopover(_ preview: MenuPreview) -> some View {
        switch preview {
        case .thumbnail:
            previewPanel(width: 344, title: l10n(.menuPrintThumbnailTitle)) {
                if let thumbnailImage {
                    Image(nsImage: thumbnailImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 260)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(SelenophileTheme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    Text(l10n(.menuNoThumbnailPreview))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SelenophileTheme.Colors.secondaryText)
                }
            }

        case .taskName(let fullName):
            previewPanel(width: 312, title: l10n(.menuTaskFullName)) {
                Text(fullName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.primaryText)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                Text(l10n(.menuCopySelectableText))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(SelenophileTheme.Colors.secondaryText)
            }
        }
    }

    private func previewPanel<Content: View>(
        width: CGFloat,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SelenophileSectionLabel(text: title)
            content()
        }
        .padding(16)
        .frame(width: width, alignment: .leading)
        .background {
            SelenophileWindowBackground()
        }
    }

    private var connectionBadgeBackground: Color {
        if store.isWaitingForManualReconnect {
            return SelenophileTheme.Colors.danger.opacity(0.04)
        }

        switch store.connectionState {
        case .connected:
            return SelenophileTheme.Colors.success.opacity(0.04)
        case .connecting, .reconnecting:
            return SelenophileTheme.Colors.accent.opacity(0.04)
        case .failed, .disconnected:
            return SelenophileTheme.Colors.danger.opacity(0.04)
        case .unconfigured:
            return SelenophileTheme.Colors.controlPressed
        }
    }

    private var connectionBadgeForeground: Color {
        if store.isWaitingForManualReconnect {
            return SelenophileTheme.Colors.danger
        }

        switch store.connectionState {
        case .connected:
            return SelenophileTheme.Colors.success
        case .connecting, .reconnecting:
            return SelenophileTheme.Colors.accentGlow
        case .failed, .disconnected:
            return SelenophileTheme.Colors.danger
        case .unconfigured:
            return SelenophileTheme.Colors.secondaryText
        }
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

private struct MenuToolTipModifier: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        content.background(MenuToolTipHostView(text: text))
    }
}

private struct MenuToolTipHostView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.toolTip = text
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = text
    }
}

private extension View {
    func menuToolTip(_ text: String) -> some View {
        modifier(MenuToolTipModifier(text: text))
    }
}
