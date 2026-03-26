import Testing
@testable import SelenophileKit

@Test
func appMetadataMatchesProjectIdentity() {
    #expect(AppConfig.appName == "Selenophile")
    #expect(AppConfig.bundleIdentifier == "com.udon.selenophile")
    #expect(AppConfig.menuTitle == "Selenophile")
}
