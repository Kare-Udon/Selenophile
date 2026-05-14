import Testing
@testable import Selenophile

@Suite("SettingsFeedbackPresentation")
struct SettingsFeedbackPresentationTests {
    @Test
    func connectionTestFeedbackSuppressesStaleStoreError() {
        let message = SettingsFeedbackPresentation.storeErrorMessage(
            "Unable to connect to Moonraker.",
            hasConnectionTestFeedback: true
        )

        #expect(message == nil)
    }

    @Test
    func storeErrorShowsWhenNoConnectionTestFeedbackExists() {
        let message = SettingsFeedbackPresentation.storeErrorMessage(
            "Unable to connect to Moonraker.",
            hasConnectionTestFeedback: false
        )

        #expect(message == "Unable to connect to Moonraker.")
    }

    @Test
    func emptyStoreErrorIsHidden() {
        let message = SettingsFeedbackPresentation.storeErrorMessage(
            "",
            hasConnectionTestFeedback: false
        )

        #expect(message == nil)
    }
}
