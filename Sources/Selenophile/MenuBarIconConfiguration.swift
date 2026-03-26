import Foundation
import SelenophileKit

struct MenuBarIconConfiguration: Equatable {
    let visibleProgress: Double
    let overlaySymbolName: String?
    let showsCenterCore: Bool

    init(
        connectionState: MoonrakerConnectionState,
        isWaitingForManualReconnect: Bool,
        hasActivePrint: Bool,
        progress: Double
    ) {
        let clampedProgress = min(max(progress, 0), 1)

        if isWaitingForManualReconnect {
            visibleProgress = max(clampedProgress, 0.22)
            overlaySymbolName = "exclamationmark.circle.fill"
            showsCenterCore = false
            return
        }

        if connectionState == .failed || connectionState == .disconnected {
            visibleProgress = max(clampedProgress, 0.22)
            overlaySymbolName = "bolt.horizontal.circle.fill"
            showsCenterCore = false
            return
        }

        if hasActivePrint {
            visibleProgress = max(clampedProgress, 0.18)
            overlaySymbolName = nil
            showsCenterCore = true
            return
        }

        visibleProgress = 1
        overlaySymbolName = Self.symbolName(for: connectionState)
        showsCenterCore = false
    }

    private static func symbolName(for connectionState: MoonrakerConnectionState) -> String {
        switch connectionState {
        case .connecting, .reconnecting:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .unconfigured:
            return "gearshape.fill"
        default:
            return "moon.stars.fill"
        }
    }
}
