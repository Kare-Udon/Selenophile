import Foundation
import Testing
@testable import SelenophileKit

@Test
func validatedWebSocketURLConvertsHTTPToWS() throws {
    let configuration = MoonrakerConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "secret-token",
        cameraSnapshotURL: "http://camera.local/snapshot.jpg"
    )

    let validated = try configuration.validated()

    #expect(validated.httpURL.absoluteString == "http://printer.local:7125")
    #expect(validated.webSocketURL.absoluteString == "ws://printer.local:7125/websocket")
    #expect(validated.apiToken == "secret-token")
    #expect(validated.cameraSnapshotURL == "http://camera.local/snapshot.jpg")
}

@Test
func validatedWebSocketURLConvertsHTTPSToWSSAndAppendsPath() throws {
    let configuration = MoonrakerConfiguration(
        serverURLString: "https://moonraker.example.com/api",
        apiToken: nil,
        cameraSnapshotURL: nil
    )

    let validated = try configuration.validated()

    #expect(validated.httpURL.absoluteString == "https://moonraker.example.com/api")
    #expect(validated.webSocketURL.absoluteString == "wss://moonraker.example.com/api/websocket")
}

@Test
func validatedWebSocketURLRejectsUnsupportedScheme() {
    let configuration = MoonrakerConfiguration(
        serverURLString: "ftp://printer.local",
        apiToken: nil,
        cameraSnapshotURL: nil
    )

    #expect(throws: MoonrakerConfigurationError.self) {
        _ = try configuration.validated()
    }
}

@Test
func moonrakerConfigurationEncodesAndDecodesAppLanguage() throws {
    let configuration = MoonrakerConfiguration(
        serverURLString: "http://printer.local:7125",
        apiToken: "secret-token",
        cameraSnapshotURL: "http://camera.local/snapshot.jpg",
        appLanguage: .japanese
    )

    let data = try JSONEncoder().encode(configuration)
    let decoded = try JSONDecoder().decode(MoonrakerConfiguration.self, from: data)

    #expect(decoded == configuration)
    #expect(decoded.appLanguage == .japanese)
}

@Test
func moonrakerConfigurationDefaultsAppLanguageWhenMissingFromLegacyJSON() throws {
    let legacyJSON = #"""
    {
      "serverURLString": "http://printer.local:7125",
      "apiToken": "secret-token",
      "cameraSnapshotURL": "http://camera.local/snapshot.jpg"
    }
    """#

    let decoded = try JSONDecoder().decode(MoonrakerConfiguration.self, from: Data(legacyJSON.utf8))

    #expect(decoded.serverURLString == "http://printer.local:7125")
    #expect(decoded.apiToken == "secret-token")
    #expect(decoded.cameraSnapshotURL == "http://camera.local/snapshot.jpg")
    #expect(decoded.appLanguage == .system)
}
