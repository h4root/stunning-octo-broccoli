import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum Theme {

    static let bgTop = Color(hex: 0x1C1722)
    static let bgBottom = Color(hex: 0x0C0A10)

    static let card = Color.white.opacity(0.05)
    static let cardElevated = Color.white.opacity(0.08)

    static let glassStroke = Color.white.opacity(0.10)
    static let glassFill = Color.white.opacity(0.05)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.32)

    static let accentPink = Color(hex: 0xFF7AB6)
    static let accentPurple = Color(hex: 0xC77DFF)
    static let lime = Color(hex: 0xC8F26B)
    static let blue = Color(hex: 0x7AB8FF)
    static let amber = Color(hex: 0xFFCE6B)
    static let green = Color(hex: 0x9BE56B)

    static let accentGradient = LinearGradient(
        colors: [accentPurple, accentPink],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let warmGlow = LinearGradient(
        colors: [Color(hex: 0xE08AC6), Color(hex: 0xF0A878)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.55 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: configuration.isPressed)
            .hoverEffect(.highlight)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bgTop, Theme.bgBottom],
                           startPoint: .top, endPoint: .bottom)

            Circle()
                .fill(Theme.accentPurple.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 120)
                .offset(x: -120, y: -260)

            Circle()
                .fill(Theme.accentPink.opacity(0.30))
                .frame(width: 360, height: 360)
                .blur(radius: 140)
                .offset(x: 150, y: 320)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var strokeOpacity: Double = 0.10

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24, strokeOpacity: Double = 0.10) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }
}

enum FeatureFlags {
    static let liquidGlass = false
}

@available(iOS 26.0, *)
func makeGlass(tint: Color?, interactive: Bool) -> Glass {
    var g: Glass = .regular
    if let tint { g = g.tint(tint) }
    if interactive { g = g.interactive() }
    return g
}

extension View {

    @ViewBuilder
    func liquidCard(_ cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = false) -> some View {
        if FeatureFlags.liquidGlass, #available(iOS 26.0, *) {
            glassEffect(makeGlass(tint: tint, interactive: interactive),
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else if let tint {
            background(tint.opacity(0.9), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            glassCard(cornerRadius: cornerRadius)
        }
    }

    @ViewBuilder
    func liquidCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        if FeatureFlags.liquidGlass, #available(iOS 26.0, *) {
            glassEffect(makeGlass(tint: tint, interactive: interactive), in: Capsule())
        } else if let tint {
            background(tint, in: Capsule())
        } else {
            background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Theme.glassStroke, lineWidth: 1))
        }
    }

    @ViewBuilder
    func liquidCircle(tint: Color? = nil, interactive: Bool = false) -> some View {
        if FeatureFlags.liquidGlass, #available(iOS 26.0, *) {
            glassEffect(makeGlass(tint: tint, interactive: interactive), in: Circle())
        } else if let tint {
            background(tint, in: Circle())
        } else {
            background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.glassStroke, lineWidth: 1))
        }
    }
}

struct AppearTransition: ViewModifier {
    var delay: Double
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func appear(_ delay: Double = 0) -> some View {
        modifier(AppearTransition(delay: delay))
    }
}

struct GlassContainer<Content: View>: View {
    var spacing: CGFloat = 24
    @ViewBuilder var content: Content

    var body: some View {
        if FeatureFlags.liquidGlass, #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

struct CircleIconButton: View {
    let systemName: String
    var tint: Color? = nil
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 46, height: 46)
                .liquidCircle(tint: tint)
        }
        .buttonStyle(.plain)
    }
}
