import Testing
@testable import Selenophile
import SelenophileKit

@Test
func activePrintAtZeroProgressUsesRealProgressAndCenterCore() {
    let configuration = MenuBarIconConfiguration(
        connectionState: .connected,
        isWaitingForManualReconnect: false,
        hasActivePrint: true,
        progress: 0
    )

    #expect(configuration.visibleProgress == 0)
    #expect(configuration.overlaySymbolName == nil)
    #expect(configuration.showsCenterCore)
}

@Test
func idlePrinterUsesIdleGlyph() {
    let configuration = MenuBarIconConfiguration(
        connectionState: .connected,
        isWaitingForManualReconnect: false,
        hasActivePrint: false,
        progress: 0.42
    )

    #expect(configuration.visibleProgress == 1)
    #expect(configuration.overlaySymbolName == "moon.stars.fill")
    #expect(!configuration.showsCenterCore)
}

@Test
func disconnectedPrinterUsesWarningGlyph() {
    let configuration = MenuBarIconConfiguration(
        connectionState: .disconnected,
        isWaitingForManualReconnect: false,
        hasActivePrint: false,
        progress: 0
    )

    #expect(configuration.visibleProgress == 0)
    #expect(configuration.overlaySymbolName == "bolt.horizontal.circle.fill")
    #expect(!configuration.showsCenterCore)
}

@Test
func manualReconnectStateUsesWarningGlyph() {
    let configuration = MenuBarIconConfiguration(
        connectionState: .failed,
        isWaitingForManualReconnect: true,
        hasActivePrint: false,
        progress: 0
    )

    #expect(configuration.visibleProgress == 0)
    #expect(configuration.overlaySymbolName == "exclamationmark.circle.fill")
    #expect(!configuration.showsCenterCore)
}
