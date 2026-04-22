import SwiftUI

enum SelenophileTheme {
    enum Colors {
        static let windowTop = Color(red: 0.086, green: 0.094, blue: 0.117)
        static let windowBottom = Color(red: 0.125, green: 0.133, blue: 0.160)
        static let surface = Color(red: 0.133, green: 0.141, blue: 0.168)
        static let surfaceRaised = Color(red: 0.155, green: 0.164, blue: 0.191)
        static let surfaceMuted = Color(red: 0.109, green: 0.117, blue: 0.141)
        static let border = Color.white.opacity(0.12)
        static let divider = Color.white.opacity(0.08)
        static let primaryText = Color.white.opacity(0.96)
        static let secondaryText = Color.white.opacity(0.64)
        static let tertiaryText = Color.white.opacity(0.42)
        static let accent = Color(red: 1.0, green: 0.42, blue: 0.10)
        static let accentPressed = Color(red: 0.89, green: 0.33, blue: 0.07)
        static let accentGlow = Color(red: 1.0, green: 0.55, blue: 0.18)
        static let success = Color(red: 0.43, green: 0.91, blue: 0.51)
        static let warning = Color(red: 0.97, green: 0.67, blue: 0.15)
        static let danger = Color(red: 1.0, green: 0.35, blue: 0.29)
        static let inputFill = Color.white.opacity(0.04)
        static let inputBorder = Color.white.opacity(0.12)
        static let shadow = Color.black.opacity(0.28)
    }

    enum Metrics {
        static let largeCorner: CGFloat = 22
        static let mediumCorner: CGFloat = 18
        static let smallCorner: CGFloat = 14
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
                    SelenophileTheme.Colors.accentGlow.opacity(0.18),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 360
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
                    .shadow(color: SelenophileTheme.Colors.shadow, radius: 24, x: 0, y: 18)
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
        HStack(spacing: 7) {
            Circle()
                .fill(foreground)
                .frame(width: 7, height: 7)

            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 12 : 13, weight: .semibold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, compact ? 0 : 16)
            .padding(.vertical, compact ? 0 : 11)
            .frame(height: compact ? 38 : 42)
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
            return .white
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
            return isPressed ? Color.white.opacity(0.08) : Color.clear
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
