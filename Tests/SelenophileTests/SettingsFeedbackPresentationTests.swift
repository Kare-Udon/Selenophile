import Testing
@testable import Selenophile
@testable import SelenophileKit

@Suite("SettingsFeedbackPresentation")
struct SettingsFeedbackPresentationTests {
    @Test
    func connectionTestFailureLocalizesRawURLSessionConnectError() {
        let message = SettingsFeedbackPresentation.connectionTestFeedbackMessage(
            .failure(.message("Could not connect to the server.")),
            language: .japanese
        )

        #expect(message == "Moonraker に接続できません。アドレス、ポート、ネットワークを確認してください。")
    }

    @Test
    func connectionTestFailureLocalizesRawURLSessionTimeoutError() {
        let message = SettingsFeedbackPresentation.connectionTestFeedbackMessage(
            .failure(.message("The request timed out.")),
            language: .simplifiedChinese
        )

        #expect(message == "连接 Moonraker 超时。")
    }

    @Test
    func connectionTestFeedbackRendersSemanticResultInCurrentLanguage() {
        #expect(
            SettingsFeedbackPresentation.connectionTestFeedbackMessage(
                .success,
                language: .english
            ) == "Connection test succeeded."
        )
        #expect(
            SettingsFeedbackPresentation.connectionTestFeedbackMessage(
                .success,
                language: .japanese
            ) == "接続テストに成功しました。"
        )
        #expect(
            SettingsFeedbackPresentation.connectionTestFeedbackMessage(
                .failure(.timeout),
                language: .simplifiedChinese
            ) == "连接测试超时。"
        )
        #expect(
            SettingsFeedbackPresentation.connectionTestFeedbackMessage(
                .failure(.timeout),
                language: .japanese
            ) == "接続テストがタイムアウトしました。"
        )
    }

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
