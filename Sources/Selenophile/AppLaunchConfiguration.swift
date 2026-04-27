import Foundation

struct AppLaunchConfiguration: Equatable {
    static let debugMainPanelArgument = "--debug-ui-window"
    static let debugMainPanelEnvironmentKey = "SELENOPHILE_DEBUG_UI_WINDOW"

    let opensDebugMainPanelWindow: Bool

    init(opensDebugMainPanelWindow: Bool = false) {
        self.opensDebugMainPanelWindow = opensDebugMainPanelWindow
    }

    init(processInfo: ProcessInfo) {
        self.init(
            opensDebugMainPanelWindow: Self.opensDebugMainPanelWindow(processInfo: processInfo)
        )
    }

    static func opensDebugMainPanelWindow(processInfo: ProcessInfo) -> Bool {
        if processInfo.arguments.contains(debugMainPanelArgument) {
            return true
        }

        guard let value = processInfo.environment[debugMainPanelEnvironmentKey] else {
            return false
        }

        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
    }
}
