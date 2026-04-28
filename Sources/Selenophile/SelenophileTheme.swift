import AppKit
import SwiftUI
import SelenophileKit

enum SelenophileThemeRuntime {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var storedPalette: AppThemePalette = .default

    static var palette: AppThemePalette {
        lock.withLock { storedPalette }
    }

    static func setPalette(_ palette: AppThemePalette) {
        lock.withLock {
            storedPalette = palette
        }
    }
}

enum SelenophileTheme {
    enum Colors {
        static var windowTop: Color { adaptive(\.windowTop) }
        static var windowBottom: Color { adaptive(\.windowBottom) }
        static var surface: Color { adaptive(\.surface) }
        static var surfaceRaised: Color { adaptive(\.surfaceRaised) }
        static var surfaceMuted: Color { adaptive(\.surfaceMuted) }
        static var border: Color { adaptive(\.border) }
        static var divider: Color { adaptive(\.divider) }
        static var primaryText: Color { adaptive(\.primaryText) }
        static var secondaryText: Color { adaptive(\.secondaryText) }
        static var tertiaryText: Color { adaptive(\.tertiaryText) }
        static var accent: Color { adaptive(\.accent) }
        static var accentText: Color { adaptive(\.accentText) }
        static var accentPressed: Color { adaptive(\.accentPressed) }
        static var secondaryAccent: Color { adaptive(\.secondaryAccent) }
        static var accentGlow: Color { adaptive(\.accentGlow) }
        static var success: Color { adaptive(\.success) }
        static var warning: Color { adaptive(\.warning) }
        static var danger: Color { adaptive(\.danger) }
        static var inputFill: Color { adaptive(\.inputFill) }
        static var inputBorder: Color { adaptive(\.inputBorder) }
        static var shadow: Color { adaptive(\.shadow) }
        static var controlPressed: Color { adaptive(\.controlPressed) }

        static func previewSwatches(for palette: AppThemePalette, colorScheme: ColorScheme) -> [Color] {
            let paletteTokens = ThemePaletteRegistry.tokens(for: palette)
            let tokens = colorScheme == .dark ? paletteTokens.dark : paletteTokens.light
            return [
                tokens.surface,
                tokens.surfaceRaised,
                tokens.accent,
                tokens.secondaryAccent,
                tokens.success,
                tokens.warning,
                tokens.danger
            ].map { Color(nsColor: $0) }
        }

        private static func adaptive(_ token: KeyPath<ThemeColorTokens, NSColor>) -> Color {
            Color(nsColor: NSColor(name: nil) { appearance in
                let bestMatch = appearance.bestMatch(from: [
                    .darkAqua,
                    .accessibilityHighContrastDarkAqua,
                    .aqua,
                    .accessibilityHighContrastAqua
                ])
                let tokens = ThemePaletteRegistry.tokens(for: SelenophileThemeRuntime.palette)
                return bestMatch?.rawValue.lowercased().contains("dark") == true
                    ? tokens.dark[keyPath: token]
                    : tokens.light[keyPath: token]
            })
        }
    }

    struct ThemeColorTokens: Sendable {
        let windowTop: NSColor
        let windowBottom: NSColor
        let surface: NSColor
        let surfaceRaised: NSColor
        let surfaceMuted: NSColor
        let border: NSColor
        let divider: NSColor
        let primaryText: NSColor
        let secondaryText: NSColor
        let tertiaryText: NSColor
        let accent: NSColor
        let accentText: NSColor
        let accentPressed: NSColor
        let secondaryAccent: NSColor
        let accentGlow: NSColor
        let success: NSColor
        let warning: NSColor
        let danger: NSColor
        let inputFill: NSColor
        let inputBorder: NSColor
        let shadow: NSColor
        let controlPressed: NSColor
    }

    struct ThemePaletteTokens: Sendable {
        let light: ThemeColorTokens
        let dark: ThemeColorTokens
    }

    private enum ThemePaletteRegistry {
        static func tokens(for palette: AppThemePalette) -> ThemePaletteTokens {
            switch palette {
            case .default:
                return defaultTokens
            case .graphite:
                return graphiteTokens
            case .github:
                return githubTokens
            case .tokyoNight:
                return tokyoNightTokens
            case .oneDark:
                return oneDarkTokens
            }
        }

        private static let defaultTokens = ThemePaletteTokens(
            light: .init(
                windowTop: color(0.965, 0.970, 0.955),
                windowBottom: color(0.900, 0.915, 0.890),
                surface: color(0.988, 0.990, 0.982),
                surfaceRaised: color(1.000, 1.000, 0.996),
                surfaceMuted: color(0.920, 0.935, 0.915),
                border: color(0.060, 0.075, 0.065, alpha: 0.14),
                divider: color(0.060, 0.075, 0.065, alpha: 0.09),
                primaryText: color(0.095, 0.110, 0.105, alpha: 0.96),
                secondaryText: color(0.300, 0.345, 0.320, alpha: 0.78),
                tertiaryText: color(0.350, 0.390, 0.365, alpha: 0.56),
                accent: color(0.900, 0.300, 0.060),
                accentText: color(0.070, 0.050, 0.040, alpha: 0.96),
                accentPressed: color(0.850, 0.360, 0.100),
                secondaryAccent: color(1.000, 0.550, 0.180),
                accentGlow: color(1.000, 0.450, 0.110),
                success: color(0.120, 0.540, 0.240),
                warning: color(0.780, 0.420, 0.020),
                danger: color(0.800, 0.140, 0.120),
                inputFill: color(1.000, 1.000, 1.000, alpha: 0.68),
                inputBorder: color(0.060, 0.075, 0.065, alpha: 0.14),
                shadow: color(0.060, 0.075, 0.065, alpha: 0.12),
                controlPressed: color(0.060, 0.075, 0.065, alpha: 0.08)
            ),
            dark: .init(
                windowTop: color(0.056, 0.061, 0.075),
                windowBottom: color(0.095, 0.102, 0.122),
                surface: color(0.111, 0.119, 0.140),
                surfaceRaised: color(0.132, 0.141, 0.164),
                surfaceMuted: color(0.083, 0.090, 0.108),
                border: color(1.000, 1.000, 1.000, alpha: 0.16),
                divider: color(1.000, 1.000, 1.000, alpha: 0.08),
                primaryText: color(1.000, 1.000, 1.000, alpha: 0.96),
                secondaryText: color(1.000, 1.000, 1.000, alpha: 0.64),
                tertiaryText: color(1.000, 1.000, 1.000, alpha: 0.42),
                accent: color(1.000, 0.420, 0.100),
                accentText: color(0.070, 0.050, 0.040, alpha: 0.96),
                accentPressed: color(0.890, 0.330, 0.070),
                secondaryAccent: color(0.970, 0.670, 0.150),
                accentGlow: color(1.000, 0.550, 0.180),
                success: color(0.430, 0.910, 0.510),
                warning: color(0.970, 0.670, 0.150),
                danger: color(1.000, 0.350, 0.290),
                inputFill: color(1.000, 1.000, 1.000, alpha: 0.04),
                inputBorder: color(1.000, 1.000, 1.000, alpha: 0.12),
                shadow: color(0.000, 0.000, 0.000, alpha: 0.34),
                controlPressed: color(1.000, 1.000, 1.000, alpha: 0.08)
            )
        )

        private static let graphiteTokens = ThemePaletteTokens(
            light: .init(
                windowTop: color(0.960, 0.965, 0.970),
                windowBottom: color(0.900, 0.910, 0.920),
                surface: color(0.985, 0.987, 0.990),
                surfaceRaised: color(1.000, 1.000, 1.000),
                surfaceMuted: color(0.920, 0.928, 0.936),
                border: color(0.060, 0.070, 0.085, alpha: 0.15),
                divider: color(0.060, 0.070, 0.085, alpha: 0.10),
                primaryText: color(0.085, 0.095, 0.110, alpha: 0.96),
                secondaryText: color(0.300, 0.325, 0.355, alpha: 0.78),
                tertiaryText: color(0.335, 0.360, 0.390, alpha: 0.56),
                accent: color(0.190, 0.420, 0.680),
                accentText: color(1.000, 1.000, 1.000),
                accentPressed: color(0.135, 0.320, 0.540),
                secondaryAccent: color(0.500, 0.560, 0.640),
                accentGlow: color(0.280, 0.520, 0.760),
                success: color(0.120, 0.500, 0.300),
                warning: color(0.720, 0.450, 0.060),
                danger: color(0.780, 0.170, 0.160),
                inputFill: color(1.000, 1.000, 1.000, alpha: 0.72),
                inputBorder: color(0.060, 0.070, 0.085, alpha: 0.15),
                shadow: color(0.060, 0.070, 0.085, alpha: 0.13),
                controlPressed: color(0.060, 0.070, 0.085, alpha: 0.08)
            ),
            dark: .init(
                windowTop: color(0.050, 0.055, 0.064),
                windowBottom: color(0.088, 0.096, 0.110),
                surface: color(0.108, 0.116, 0.132),
                surfaceRaised: color(0.130, 0.140, 0.158),
                surfaceMuted: color(0.080, 0.087, 0.100),
                border: color(1.000, 1.000, 1.000, alpha: 0.15),
                divider: color(1.000, 1.000, 1.000, alpha: 0.08),
                primaryText: color(1.000, 1.000, 1.000, alpha: 0.96),
                secondaryText: color(1.000, 1.000, 1.000, alpha: 0.64),
                tertiaryText: color(1.000, 1.000, 1.000, alpha: 0.42),
                accent: color(0.470, 0.680, 0.940),
                accentText: color(0.060, 0.085, 0.120),
                accentPressed: color(0.360, 0.560, 0.820),
                secondaryAccent: color(0.760, 0.800, 0.860),
                accentGlow: color(0.540, 0.740, 1.000),
                success: color(0.420, 0.860, 0.560),
                warning: color(0.950, 0.680, 0.210),
                danger: color(1.000, 0.380, 0.340),
                inputFill: color(1.000, 1.000, 1.000, alpha: 0.04),
                inputBorder: color(1.000, 1.000, 1.000, alpha: 0.12),
                shadow: color(0.000, 0.000, 0.000, alpha: 0.34),
                controlPressed: color(1.000, 1.000, 1.000, alpha: 0.08)
            )
        )

        private static let githubTokens = ThemePaletteTokens(
            light: .init(
                windowTop: hex(0xffffff),
                windowBottom: hex(0xf6f8fa),
                surface: hex(0xf6f8fa),
                surfaceRaised: hex(0xffffff),
                surfaceMuted: hex(0xf6f8fa),
                border: hex(0xd0d7de),
                divider: hex(0xd0d7de, alpha: 0.62),
                primaryText: hex(0x1f2328),
                secondaryText: hex(0x656d76),
                tertiaryText: hex(0x656d76, alpha: 0.68),
                accent: hex(0x0969da),
                accentText: hex(0xffffff),
                accentPressed: hex(0x0969da, alpha: 0.82),
                secondaryAccent: hex(0x8250df),
                accentGlow: hex(0x0969da),
                success: hex(0x116329),
                warning: hex(0x7d4e00),
                danger: hex(0xa40e26),
                inputFill: hex(0xffffff, alpha: 0.76),
                inputBorder: hex(0xd0d7de),
                shadow: hex(0x1f2328, alpha: 0.12),
                controlPressed: hex(0x1f2328, alpha: 0.08)
            ),
            dark: .init(
                windowTop: hex(0x0d1117),
                windowBottom: hex(0x161b22),
                surface: hex(0x161b22),
                surfaceRaised: hex(0x21262d),
                surfaceMuted: hex(0x21262d),
                border: hex(0x30363d),
                divider: hex(0x21262d),
                primaryText: hex(0xe6edf3),
                secondaryText: hex(0x7d8590),
                tertiaryText: hex(0x7d8590, alpha: 0.68),
                accent: hex(0x1f6feb),
                accentText: hex(0xffffff),
                accentPressed: hex(0x1158c7),
                secondaryAccent: hex(0xa371f7),
                accentGlow: hex(0x2f81f7),
                success: hex(0x3fb950),
                warning: hex(0xd29922),
                danger: hex(0xf85149),
                inputFill: hex(0x21262d, alpha: 0.82),
                inputBorder: hex(0x30363d),
                shadow: hex(0x000000, alpha: 0.34),
                controlPressed: hex(0xe6edf3, alpha: 0.08)
            )
        )

        private static let tokyoNightTokens = ThemePaletteTokens(
            light: .init(
                windowTop: hex(0xe1e2e7),
                windowBottom: hex(0xd0d5e3),
                surface: hex(0xd0d5e3),
                surfaceRaised: hex(0xe1e2e7),
                surfaceMuted: hex(0xa8aecb),
                border: hex(0x8990b3),
                divider: hex(0xa8aecb),
                primaryText: hex(0x1f2a66),
                secondaryText: hex(0x3b426f),
                tertiaryText: hex(0x3b426f, alpha: 0.68),
                accent: hex(0x6b46c1),
                accentText: hex(0xffffff),
                accentPressed: hex(0x553c9a),
                secondaryAccent: hex(0x2e7de9),
                accentGlow: hex(0x7aa2f7),
                success: hex(0x34540c),
                warning: hex(0x674800),
                danger: hex(0x9c1c28),
                inputFill: hex(0xe1e2e7, alpha: 0.74),
                inputBorder: hex(0x8990b3),
                shadow: hex(0x3760bf, alpha: 0.14),
                controlPressed: hex(0x3760bf, alpha: 0.09)
            ),
            dark: .init(
                windowTop: hex(0x24283b),
                windowBottom: hex(0x1f2335),
                surface: hex(0x1f2335),
                surfaceRaised: hex(0x292e42),
                surfaceMuted: hex(0x292e42),
                border: hex(0x414868),
                divider: hex(0x292e42),
                primaryText: hex(0xc0caf5),
                secondaryText: hex(0xa9b1d6),
                tertiaryText: hex(0xa9b1d6, alpha: 0.68),
                accent: hex(0x6f52b8),
                accentText: hex(0xffffff),
                accentPressed: hex(0x5b419b),
                secondaryAccent: hex(0x7dcfff),
                accentGlow: hex(0xbb9af7),
                success: hex(0x9ece6a),
                warning: hex(0xe0af68),
                danger: hex(0xf7768e),
                inputFill: hex(0x292e42, alpha: 0.82),
                inputBorder: hex(0x414868),
                shadow: hex(0x000000, alpha: 0.34),
                controlPressed: hex(0xc0caf5, alpha: 0.08)
            )
        )

        private static let oneDarkTokens = ThemePaletteTokens(
            light: .init(
                windowTop: hex(0xfafafa),
                windowBottom: hex(0xf0f0f0),
                surface: hex(0xf0f0f0),
                surfaceRaised: hex(0xfafafa),
                surfaceMuted: hex(0xd8d8d8),
                border: hex(0xc8ccd4),
                divider: hex(0xd8d8d8),
                primaryText: hex(0x383a42),
                secondaryText: hex(0x696c77),
                tertiaryText: hex(0x696c77, alpha: 0.68),
                accent: hex(0x7f3fa6),
                accentText: hex(0xffffff),
                accentPressed: hex(0x633283),
                secondaryAccent: hex(0xd19a66),
                accentGlow: hex(0xc678dd),
                success: hex(0x2f6f2e),
                warning: hex(0x7c4f00),
                danger: hex(0xb7322c),
                inputFill: hex(0xfafafa, alpha: 0.76),
                inputBorder: hex(0xc8ccd4),
                shadow: hex(0x383a42, alpha: 0.12),
                controlPressed: hex(0x383a42, alpha: 0.08)
            ),
            dark: .init(
                windowTop: hex(0x282c34),
                windowBottom: hex(0x21252b),
                surface: hex(0x21252b),
                surfaceRaised: hex(0x3e4452),
                surfaceMuted: hex(0x3e4452),
                border: hex(0x404754),
                divider: hex(0x3e4452),
                primaryText: hex(0xabb2bf),
                secondaryText: hex(0x9da5b4),
                tertiaryText: hex(0x9da5b4, alpha: 0.68),
                accent: hex(0x7f3fa6),
                accentText: hex(0xffffff),
                accentPressed: hex(0x633283),
                secondaryAccent: hex(0xd19a66),
                accentGlow: hex(0xc678dd),
                success: hex(0x98c379),
                warning: hex(0xe5c07b),
                danger: hex(0xe06c75),
                inputFill: hex(0x3e4452, alpha: 0.76),
                inputBorder: hex(0x404754),
                shadow: hex(0x000000, alpha: 0.34),
                controlPressed: hex(0xabb2bf, alpha: 0.08)
            )
        )

        private static func hex(_ value: UInt32, alpha: CGFloat = 1) -> NSColor {
            precondition(value <= 0xffffff, "Theme hex colors must use 24-bit RGB literals.")
            return color(
                CGFloat((value >> 16) & 0xff) / 255,
                CGFloat((value >> 8) & 0xff) / 255,
                CGFloat(value & 0xff) / 255,
                alpha: alpha
            )
        }

        private static func color(
            _ red: CGFloat,
            _ green: CGFloat,
            _ blue: CGFloat,
            alpha: CGFloat = 1
        ) -> NSColor {
            NSColor(
                calibratedRed: red,
                green: green,
                blue: blue,
                alpha: alpha
            )
        }
    }

    enum Metrics {
        static let largeCorner: CGFloat = 12
        static let mediumCorner: CGFloat = 8
        static let smallCorner: CGFloat = 8
    }
}

struct SelenophileWindowBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SelenophileTheme.Colors.windowTop,
                    SelenophileTheme.Colors.windowBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    SelenophileTheme.Colors.accentGlow.opacity(0.13),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 320
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

struct SelenophileCardModifier: ViewModifier {
    var cornerRadius: CGFloat = SelenophileTheme.Metrics.largeCorner
    var fill: Color = SelenophileTheme.Colors.surface
    var strokeOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(SelenophileTheme.Colors.border.opacity(strokeOpacity), lineWidth: 1)
                    }
                    .shadow(color: SelenophileTheme.Colors.shadow, radius: 18, x: 0, y: 12)
            )
    }
}

extension View {
    func selenophileCard(
        cornerRadius: CGFloat = SelenophileTheme.Metrics.largeCorner,
        fill: Color = SelenophileTheme.Colors.surface,
        strokeOpacity: Double = 1
    ) -> some View {
        modifier(
            SelenophileCardModifier(
                cornerRadius: cornerRadius,
                fill: fill,
                strokeOpacity: strokeOpacity
            )
        )
    }
}

struct SelenophileSectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(SelenophileTheme.Colors.secondaryText)
            .textCase(.uppercase)
            .tracking(1.8)
    }
}

struct SelenophileStatusBadge: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(foreground)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.0)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(background, in: Capsule())
    }
}

struct SelenophileButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case ghost
        case destructive
    }

    let kind: Kind
    var compact = false
    var fullWidth = false
    var scale: CGFloat = 1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: (compact ? 12 : 13) * scale, weight: .semibold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, compact ? 0 : 13 * scale)
            .padding(.vertical, compact ? 0 : 8 * scale)
            .frame(width: compact ? 34 * scale : nil, height: compact ? 34 * scale : 36 * scale)
            .background(background(configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            return SelenophileTheme.Colors.accentText
        case .secondary:
            return SelenophileTheme.Colors.primaryText
        case .ghost:
            return SelenophileTheme.Colors.secondaryText
        case .destructive:
            return SelenophileTheme.Colors.danger
        }
    }

    private var borderColor: Color {
        switch kind {
        case .primary:
            return .clear
        case .secondary, .ghost:
            return SelenophileTheme.Colors.border
        case .destructive:
            return SelenophileTheme.Colors.danger.opacity(0.4)
        }
    }

    private var borderWidth: CGFloat {
        kind == .primary ? 0 : 1
    }

    private func background(_ isPressed: Bool) -> Color {
        switch kind {
        case .primary:
            return isPressed ? SelenophileTheme.Colors.accentPressed : SelenophileTheme.Colors.accent
        case .secondary:
            return isPressed ? SelenophileTheme.Colors.surfaceRaised : SelenophileTheme.Colors.surface
        case .ghost:
            return isPressed ? SelenophileTheme.Colors.controlPressed : Color.clear
        case .destructive:
            return isPressed ? SelenophileTheme.Colors.danger.opacity(0.18) : SelenophileTheme.Colors.danger.opacity(0.10)
        }
    }
}

struct SelenophileTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(SelenophileTheme.Colors.primaryText)
            .textFieldStyle(.plain)
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .fill(SelenophileTheme.Colors.inputFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SelenophileTheme.Metrics.smallCorner, style: .continuous)
                    .stroke(SelenophileTheme.Colors.inputBorder, lineWidth: 1)
            }
    }
}
