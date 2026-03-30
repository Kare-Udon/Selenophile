import ServiceManagement

protocol LaunchAtLoginServiceProviding {
    var status: LaunchAtLoginStatus { get }
    func register() throws
    func unregister() throws
}

enum LaunchAtLoginStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval

    var isEnabled: Bool {
        self == .enabled
    }

    init(serviceStatus: SMAppService.Status) {
        switch serviceStatus {
        case .enabled:
            self = .enabled
        case .notRegistered, .notFound:
            self = .disabled
        case .requiresApproval:
            self = .requiresApproval
        @unknown default:
            self = .disabled
        }
    }
}

struct LaunchAtLoginController {
    private let service: any LaunchAtLoginServiceProviding

    init(service: any LaunchAtLoginServiceProviding = SystemLaunchAtLoginService()) {
        self.service = service
    }

    var isEnabled: Bool {
        service.status.isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}

struct SystemLaunchAtLoginService: LaunchAtLoginServiceProviding {
    private let appService: SMAppService

    init(appService: SMAppService = .mainApp) {
        self.appService = appService
    }

    var status: LaunchAtLoginStatus {
        LaunchAtLoginStatus(serviceStatus: appService.status)
    }

    func register() throws {
        try appService.register()
    }

    func unregister() throws {
        try appService.unregister()
    }
}
