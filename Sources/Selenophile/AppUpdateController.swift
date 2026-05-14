import Foundation
import Sparkle
import SelenophileKit

@MainActor
protocol AppUpdateChecking: AnyObject {
    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    func checkForUpdates()
}

@MainActor
enum AppUpdateDefaults {
    static let automaticCheckInterval: TimeInterval = 86_400
}

@MainActor
enum AppUpdateConfiguration {
    static func isConfigured(bundle: Bundle = .main) -> Bool {
        guard
            let feedURLString = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            let feedURL = URL(string: feedURLString),
            let scheme = feedURL.scheme?.lowercased(),
            scheme == "https",
            feedURL.host?.lowercased() != "example.com",
            let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        else {
            return false
        }

        let trimmedPublicKey = publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedPublicKey.isEmpty
            && !trimmedPublicKey.contains("$(")
            && !trimmedPublicKey.localizedCaseInsensitiveContains("replace")
    }
}

@MainActor
final class SparkleUpdateController: AppUpdateChecking {
    private let updaterController: SPUStandardUpdaterController

    init(checkOnLaunch: Bool = true) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updaterController.updater.updateCheckInterval = AppUpdateDefaults.automaticCheckInterval
        if checkOnLaunch && updaterController.updater.automaticallyChecksForUpdates {
            updaterController.updater.checkForUpdatesInBackground()
        }
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    var automaticallyChecksForUpdates: Bool {
        get {
            updaterController.updater.automaticallyChecksForUpdates
        }
        set {
            updaterController.updater.automaticallyChecksForUpdates = newValue
        }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    static func makeIfConfigured(logStore: AppLogStore, bundle: Bundle = .main) -> SparkleUpdateController? {
        guard AppUpdateConfiguration.isConfigured(bundle: bundle) else {
            logStore.log(
                .info,
                source: "Sparkle",
                message: "Sparkle update checks are disabled until SUFeedURL and SUPublicEDKey are configured"
            )
            return nil
        }

        return SparkleUpdateController()
    }
}
