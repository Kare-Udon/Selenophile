import Foundation
import AppKit
import SwiftUI
import Testing
@testable import Selenophile
@testable import SelenophileKit

@MainActor
@Test
func appAppearanceStoreDefaultsToDarkWhenNoPreferenceExists() {
    let defaults = UserDefaults(suiteName: "AppAppearanceStoreTests.default.\(UUID().uuidString)")!

    let store = AppAppearanceStore(defaults: defaults)

    #expect(store.selectedMode == .dark)
    #expect(store.persistedMode == .dark)
}

@MainActor
@Test
func appAppearanceStorePersistsSelectedMode() {
    let defaults = UserDefaults(suiteName: "AppAppearanceStoreTests.persist.\(UUID().uuidString)")!

    let store = AppAppearanceStore(defaults: defaults)
    store.save(.light)

    let reloaded = AppAppearanceStore(defaults: defaults)

    #expect(store.selectedMode == .light)
    #expect(store.persistedMode == .light)
    #expect(reloaded.selectedMode == .light)
}

@MainActor
@Test
func appAppearanceStorePersistsSelectedPalette() {
    let defaults = UserDefaults(suiteName: "AppAppearanceStoreTests.palette.\(UUID().uuidString)")!

    let store = AppAppearanceStore(defaults: defaults)
    store.save(mode: .light, palette: .graphite)

    let reloaded = AppAppearanceStore(defaults: defaults)

    #expect(store.selectedMode == .light)
    #expect(store.selectedPalette == .graphite)
    #expect(store.persistedMode == .light)
    #expect(store.persistedPalette == .graphite)
    #expect(reloaded.selectedMode == .light)
    #expect(reloaded.selectedPalette == .graphite)
}

@MainActor
@Test
func appAppearanceStoreCanPreviewAndRestorePersistedMode() {
    let defaults = UserDefaults(suiteName: "AppAppearanceStoreTests.preview.\(UUID().uuidString)")!

    let store = AppAppearanceStore(defaults: defaults)
    store.save(.dark)
    store.save(mode: .dark, palette: .default)
    store.preview(mode: .system, palette: .graphite)
    store.restorePersistedMode()

    #expect(store.selectedMode == .dark)
    #expect(store.persistedMode == .dark)
    #expect(store.selectedPalette == .default)
    #expect(store.persistedPalette == .default)
}

@MainActor
@Test
func appAppearancePreviewColorsResolveCurrentPaletteWithoutSaving() throws {
    let defaults = UserDefaults(suiteName: "AppAppearanceStoreTests.repaint.\(UUID().uuidString)")!
    let store = AppAppearanceStore(defaults: defaults)
    store.save(mode: .light, palette: .default)

    let defaultAccent = try renderedAccentColor()
    store.preview(mode: .light, palette: .graphite)

    let previewAccent = try renderedAccentColor()

    #expect(previewAccent != defaultAccent)
    #expect(store.persistedPalette == .default)
}

@MainActor
@Test
func appAppearanceModeResolvesSystemModeToCurrentSystemScheme() {
    #expect(AppAppearanceMode.light.resolvedColorScheme(systemColorScheme: .dark) == .light)
    #expect(AppAppearanceMode.dark.resolvedColorScheme(systemColorScheme: .light) == .dark)
    #expect(AppAppearanceMode.system.resolvedColorScheme(systemColorScheme: .dark) == .dark)
    #expect(AppAppearanceMode.system.resolvedColorScheme(systemColorScheme: .light) == .light)
}

private struct PaletteAccentProbeView: View {
    var body: some View {
        Rectangle()
            .fill(SelenophileTheme.Colors.accent)
            .frame(width: 24, height: 24)
    }
}

@MainActor
private func renderedAccentColor() throws -> RGBSample {
    let host = NSHostingView(rootView: PaletteAccentProbeView())
    host.frame = NSRect(x: 0, y: 0, width: 24, height: 24)
    return try renderedCenterColor(from: host)
}

@MainActor
private func renderedCenterColor(from host: NSHostingView<some View>) throws -> RGBSample {
    host.layoutSubtreeIfNeeded()
    let representation = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
    host.cacheDisplay(in: host.bounds, to: representation)
    let color = try #require(representation.colorAt(x: Int(host.bounds.midX), y: Int(host.bounds.midY)))
    let rgb = try #require(color.usingColorSpace(.deviceRGB))

    return RGBSample(
        red: Int((rgb.redComponent * 255).rounded()),
        green: Int((rgb.greenComponent * 255).rounded()),
        blue: Int((rgb.blueComponent * 255).rounded())
    )
}

private struct RGBSample: Equatable, CustomStringConvertible {
    let red: Int
    let green: Int
    let blue: Int

    var description: String {
        "rgb(\(red), \(green), \(blue))"
    }
}
