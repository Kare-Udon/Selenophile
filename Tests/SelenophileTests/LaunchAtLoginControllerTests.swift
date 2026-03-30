import Testing
@testable import Selenophile

@Test
func launchAtLoginControllerReadsAndWritesThroughInjectedService() throws {
    let service = LaunchAtLoginServiceSpy(status: .disabled)
    let controller = LaunchAtLoginController(service: service)

    #expect(!controller.isEnabled)

    try controller.setEnabled(true)

    #expect(service.registerCallCount == 1)
    #expect(service.unregisterCallCount == 0)
    #expect(controller.isEnabled)

    try controller.setEnabled(false)

    #expect(service.registerCallCount == 1)
    #expect(service.unregisterCallCount == 1)
    #expect(!controller.isEnabled)
}

@Test
func launchAtLoginControllerTreatsRequiresApprovalAsDisabled() {
    let service = LaunchAtLoginServiceSpy(status: .requiresApproval)
    let controller = LaunchAtLoginController(service: service)

    #expect(!controller.isEnabled)
}

@MainActor
@Test
func appDelegateStoresInjectedLaunchAtLoginController() {
    let controller = LaunchAtLoginController(service: LaunchAtLoginServiceSpy(status: .enabled))
    let appDelegate = AppDelegate(
        launchAtLoginController: controller,
        appLanguageStore: AppLanguageStore()
    )

    #expect(appDelegate.launchAtLoginController.isEnabled)
}

private final class LaunchAtLoginServiceSpy: LaunchAtLoginServiceProviding {
    var status: LaunchAtLoginStatus
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(status: LaunchAtLoginStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        status = .disabled
    }
}
