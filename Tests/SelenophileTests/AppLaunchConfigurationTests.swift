import Foundation
import Testing
@testable import Selenophile

@Test
func appLaunchConfigurationDefaultsToDisabled() {
    let processInfo = StubProcessInfo(arguments: ["Selenophile"], environment: [:])

    #expect(AppLaunchConfiguration(processInfo: processInfo).opensDebugMainPanelWindow == false)
}

@Test
func appLaunchConfigurationEnablesDebugWindowFromArgument() {
    let processInfo = StubProcessInfo(
        arguments: ["Selenophile", AppLaunchConfiguration.debugMainPanelArgument],
        environment: [:]
    )

    #expect(AppLaunchConfiguration(processInfo: processInfo).opensDebugMainPanelWindow)
}

@Test
func appLaunchConfigurationEnablesDebugWindowFromEnvironment() {
    let processInfo = StubProcessInfo(
        arguments: ["Selenophile"],
        environment: [AppLaunchConfiguration.debugMainPanelEnvironmentKey: "true"]
    )

    #expect(AppLaunchConfiguration(processInfo: processInfo).opensDebugMainPanelWindow)
}

@Test
func appLaunchConfigurationIgnoresFalseyEnvironmentValue() {
    let processInfo = StubProcessInfo(
        arguments: ["Selenophile"],
        environment: [AppLaunchConfiguration.debugMainPanelEnvironmentKey: "0"]
    )

    #expect(AppLaunchConfiguration(processInfo: processInfo).opensDebugMainPanelWindow == false)
}

private final class StubProcessInfo: ProcessInfo, @unchecked Sendable {
    private let stubArguments: [String]
    private let stubEnvironment: [String: String]

    init(arguments: [String], environment: [String: String]) {
        self.stubArguments = arguments
        self.stubEnvironment = environment
        super.init()
    }

    override var arguments: [String] {
        stubArguments
    }

    override var environment: [String: String] {
        stubEnvironment
    }
}
