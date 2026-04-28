import Foundation
import Observation
import SwiftUI
import AppKit
import SelenophileKit

@MainActor
@Observable
final class AppAppearanceStore {
    static let shared = AppAppearanceStore()

    private static let appearanceUserDefaultsKey = "app.appearance.mode"
    private static let paletteUserDefaultsKey = "app.theme.palette"
    private let defaults: UserDefaults

    var selectedMode: AppAppearanceMode
    var selectedPalette: AppThemePalette

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedMode = Self.loadPersistedMode(from: defaults)
        self.selectedPalette = Self.loadPersistedPalette(from: defaults)
        SelenophileThemeRuntime.setPalette(selectedPalette)
    }

    var persistedMode: AppAppearanceMode {
        Self.loadPersistedMode(from: defaults)
    }

    var persistedPalette: AppThemePalette {
        Self.loadPersistedPalette(from: defaults)
    }

    func preview(_ mode: AppAppearanceMode) {
        selectedMode = mode
    }

    func preview(mode: AppAppearanceMode, palette: AppThemePalette) {
        selectedMode = mode
        selectedPalette = palette
        SelenophileThemeRuntime.setPalette(palette)
    }

    func save(_ mode: AppAppearanceMode) {
        save(mode: mode, palette: selectedPalette)
    }

    func save(mode: AppAppearanceMode, palette: AppThemePalette) {
        selectedMode = mode
        selectedPalette = palette
        defaults.set(mode.rawValue, forKey: Self.appearanceUserDefaultsKey)
        defaults.set(palette.rawValue, forKey: Self.paletteUserDefaultsKey)
        SelenophileThemeRuntime.setPalette(palette)
    }

    func restorePersistedMode() {
        selectedMode = persistedMode
        selectedPalette = persistedPalette
        SelenophileThemeRuntime.setPalette(selectedPalette)
    }

    private static func loadPersistedMode(from defaults: UserDefaults) -> AppAppearanceMode {
        guard let rawValue = defaults.string(forKey: appearanceUserDefaultsKey),
              let mode = AppAppearanceMode(rawValue: rawValue)
        else {
            return .dark
        }

        return mode
    }

    private static func loadPersistedPalette(from defaults: UserDefaults) -> AppThemePalette {
        guard let rawValue = defaults.string(forKey: paletteUserDefaultsKey),
              let palette = AppThemePalette(rawValue: rawValue)
        else {
            return .default
        }

        return palette
    }
}

extension AppAppearanceMode {
    @MainActor
    func resolvedColorScheme(systemColorScheme: ColorScheme? = nil) -> ColorScheme {
        switch self {
        case .system:
            return systemColorScheme ?? SystemAppearance.currentColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
private enum SystemAppearance {
    static var currentColorScheme: ColorScheme {
        let appearance = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
        return appearance == .darkAqua ? .dark : .light
    }
}

extension View {
    func selenophileAppearance(_ appearanceStore: AppAppearanceStore) -> some View {
        SelenophileAppearanceContainer(
            appearanceStore: appearanceStore,
            content: self
        )
    }
}

private struct SelenophileAppearanceContainer<Content: View>: View {
    let appearanceStore: AppAppearanceStore
    let content: Content

    var body: some View {
        content
            .environment(\.selenophileThemePalette, appearanceStore.selectedPalette)
            .preferredColorScheme(appearanceStore.selectedMode.resolvedColorScheme())
    }
}

private struct SelenophileThemePaletteKey: EnvironmentKey {
    static let defaultValue: AppThemePalette = .default
}

private extension EnvironmentValues {
    var selenophileThemePalette: AppThemePalette {
        get { self[SelenophileThemePaletteKey.self] }
        set { self[SelenophileThemePaletteKey.self] = newValue }
    }
}
