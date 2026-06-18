import SwiftUI
import UIKit

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

    init(lightHex: UInt, darkHex: UInt) {
        self = Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? darkHex : lightHex
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

private func ink(_ opacity: Double) -> Color {
    Color(UIColor { trait in
        UIColor(white: trait.userInterfaceStyle == .dark ? 1 : 0, alpha: opacity)
    })
}

enum Theme {

    static let acidUIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.80, green: 1.0, blue: 0.0, alpha: 1)
            : UIColor(red: 0.36, green: 0.60, blue: 0.0, alpha: 1)
    }
    static let onAccentUIColor = UIColor { $0.userInterfaceStyle == .dark ? .black : .white }

    static let acid = Color(acidUIColor)
    static let onAccent = Color(onAccentUIColor)

    static let bgTop = Color(lightHex: 0xFFFFFF, darkHex: 0x171717)
    static let bgBottom = Color(lightHex: 0xECECEF, darkHex: 0x000000)
    static let flatBackground = Color(lightHex: 0xEFEFF2, darkHex: 0x121214)
    static let surface = Color(lightHex: 0xFFFFFF, darkHex: 0x1E1E20)

    static let card = ink(0.05)
    static let cardElevated = ink(0.08)

    static let glassStroke = ink(0.14)
    static let glassFill = ink(0.05)

    static let textPrimary = ink(1)
    static let textSecondary = ink(0.55)
    static let textTertiary = ink(0.32)

    static let accentPink = acid
    static let accentPurple = acid
    static let lime = ink(0.85)
    static let blue = ink(0.85)
    static let amber = acid
    static let green = ink(0.85)

    static let accentGradient = LinearGradient(
        colors: [Color(lightHex: 0x6FB300, darkHex: 0xDDFF66), Color(lightHex: 0x4E8C00, darkHex: 0xAEEA00)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let warmGlow = accentGradient

    static let fire = acid
    static let fireGradient = LinearGradient(
        colors: [Color(lightHex: 0x7AC400, darkHex: 0xE6FF7A), Color(lightHex: 0x4E8C00, darkHex: 0xB6F000)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

enum AppAppearance: String {
    case auto, dark, light
    var scheme: ColorScheme? {
        switch self {
        case .auto:  return nil
        case .dark:  return .dark
        case .light: return .light
        }
    }
}

struct AppearanceModifier: ViewModifier {
    @AppStorage("appearance") private var raw = AppAppearance.dark.rawValue
    func body(content: Content) -> some View {
        content.preferredColorScheme((AppAppearance(rawValue: raw) ?? .dark).scheme)
    }
}

extension View {
    func appAppearance() -> some View { modifier(AppearanceModifier()) }

    @ViewBuilder
    func sheetMaterialBackground() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(.ultraThinMaterial)
        } else {
            self
        }
    }

    @ViewBuilder
    func bottomScrollInset(_ amount: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            self.contentMargins(.bottom, amount, for: .scrollContent)
        } else {
            self
        }
    }
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
            RadialGradient(colors: [Theme.textPrimary.opacity(0.05), .clear],
                           center: .top, startRadius: 0, endRadius: 460)
        }
        .ignoresSafeArea()
    }
}

struct LavaBlob: Identifiable {
    let id = UUID()
    let size: CGFloat
    let ampX: CGFloat
    let ampY: CGFloat
    let speed: Double
    let phase: Double
    let baseX: CGFloat
    let baseY: CGFloat
    let colorIndex: Int
}

struct LavaRipple: Identifiable {
    let id = UUID()
    let color: Color
    let start: Date
    let unitX: CGFloat
    let unitY: CGFloat
}

private func lavaLerp(_ a: Color, _ b: Color, _ t: Double) -> Color {
    let ua = UIColor(a), ub = UIColor(b)
    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
    ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
    let f = CGFloat(min(max(t, 0), 1))
    return Color(.sRGB,
                 red: Double(r1 + (r2 - r1) * f),
                 green: Double(g1 + (g2 - g1) * f),
                 blue: Double(b1 + (b2 - b1) * f),
                 opacity: Double(a1 + (a2 - a1) * f))
}

struct LavaLampBackground: View {
    var colors: [Color]
    var baseTop: Color
    var baseBottom: Color
    var blobOpacity: Double = 0.5
    var ripples: [LavaRipple] = []
    var focus: UnitPoint = UnitPoint(x: 0.5, y: 0.32)

    @State private var fromPalette: [Color] = []
    @State private var toPalette: [Color] = []
    @State private var transitionStart: Date = .distantPast

    private let transitionDuration: Double = 1.8
    private let rippleLife: Double = 1.5

    private static let blobs: [LavaBlob] = [
        LavaBlob(size: 320, ampX: 0.18, ampY: 0.16, speed: 0.10, phase: 0.0, baseX: 0.30, baseY: 0.28, colorIndex: 0),
        LavaBlob(size: 380, ampX: 0.22, ampY: 0.20, speed: 0.07, phase: 1.7, baseX: 0.72, baseY: 0.40, colorIndex: 1),
        LavaBlob(size: 280, ampX: 0.20, ampY: 0.24, speed: 0.12, phase: 3.1, baseX: 0.45, baseY: 0.70, colorIndex: 2),
        LavaBlob(size: 240, ampX: 0.26, ampY: 0.18, speed: 0.09, phase: 4.6, baseX: 0.80, baseY: 0.78, colorIndex: 3),
        LavaBlob(size: 300, ampX: 0.16, ampY: 0.22, speed: 0.06, phase: 2.3, baseX: 0.18, baseY: 0.84, colorIndex: 4)
    ]

    private func resolve(_ b: LavaBlob, _ palette: [Color]) -> Color {
        let p = palette.isEmpty ? colors : palette
        return p.isEmpty ? .clear : p[b.colorIndex % p.count]
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let prog = min(max((t - transitionStart.timeIntervalSinceReferenceDate) / transitionDuration, 0), 1)
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    LinearGradient(colors: [baseTop, baseBottom], startPoint: .top, endPoint: .bottom)

                    ZStack {
                        ForEach(Self.blobs) { b in
                            let x = w * (b.baseX + b.ampX * CGFloat(sin(t * b.speed + b.phase)))
                            let y = h * (b.baseY + b.ampY * CGFloat(cos(t * b.speed * 0.8 + b.phase)))
                            let s = b.size * (1 + 0.10 * CGFloat(sin(t * b.speed * 1.3 + b.phase)))
                            let fill = lavaLerp(resolve(b, fromPalette), resolve(b, toPalette), prog)
                            Circle()
                                .fill(fill)
                                .frame(width: s, height: s)
                                .position(x: x, y: y)
                                .blur(radius: 70)
                                .opacity(blobOpacity)
                        }
                        ForEach(ripples) { r in
                            let age = t - r.start.timeIntervalSinceReferenceDate
                            if age >= 0 && age < rippleLife {
                                let p = age / rippleLife
                                Circle()
                                    .fill(r.color)
                                    .frame(width: 70 + CGFloat(p) * 460, height: 70 + CGFloat(p) * 460)
                                    .position(x: w * r.unitX, y: h * r.unitY)
                                    .opacity((1 - p) * 0.55)
                                    .blur(radius: 45)
                            }
                        }
                    }
                    .blendMode(.plusLighter)
                    .drawingGroup()

                    RadialGradient(colors: [.black.opacity(0.30), .clear],
                                   center: focus, startRadius: 8, endRadius: 280)
                    LinearGradient(colors: [.black.opacity(0.10), .clear, .black.opacity(0.22)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            if toPalette.isEmpty { toPalette = colors; fromPalette = colors }
        }
        .onChange(of: colors) { new in
            fromPalette = toPalette.isEmpty ? new : toPalette
            toPalette = new
            transitionStart = Date()
        }
    }
}

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var strokeOpacity: Double = 0.12

    func body(content: Content) -> some View {
        if FeatureFlags.liquidGlass, #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.textPrimary.opacity(strokeOpacity), lineWidth: 0.5)
                )
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.textPrimary.opacity(strokeOpacity), lineWidth: 1)
                )
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24, strokeOpacity: Double = 0.10) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }

    func solidCard(cornerRadius: CGFloat = 18) -> some View {
        self
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.textPrimary.opacity(0.10), lineWidth: 1)
            )
    }
}

enum FeatureFlags {
    static let liquidGlass = true
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
