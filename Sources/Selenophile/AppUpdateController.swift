import Foundation
import Sparkle
import SelenophileKit

@MainActor
protocol AppUpdateChecking {
    var canCheckForUpdates: Bool { get }
    func checkForUpdates()
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

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
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
