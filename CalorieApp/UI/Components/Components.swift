import SwiftUI

enum Fmt {
    static func g(_ value: Double) -> String {
        if value >= 100 { return String(format: "%.0f", value) }
        return String(format: "%.1f", value)
    }

    static func kcal(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}

enum MacroColor {
    static let kcal = Theme.acid
    static let protein = Theme.textPrimary.opacity(0.92)
    static let fat = Theme.textPrimary.opacity(0.55)
    static let carbs = Theme.textPrimary.opacity(0.32)
}

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.textPrimary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress > 1 {
                Circle()
                    .trim(from: 0, to: min(progress - 1, 1))
                    .stroke(color.opacity(0.45),
                            style: StrokeStyle(lineWidth: lineWidth * 0.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .animation(.easeOut(duration: 0.4), value: progress)
    }
}

struct CalorieSummaryRing: View {
    var consumed: Double
    var goal: Double

    private var progress: Double { goal > 0 ? consumed / goal : 0 }
    private var remaining: Double { max(goal - consumed, 0) }
    private var shown: Double { min(progress, 1) }

    var body: some View {
        ZStack {

            Color.clear
                .frame(width: 186, height: 186)
                .liquidCircle()

            Circle()
                .stroke(Theme.textPrimary.opacity(0.07), lineWidth: 16)
                .padding(14)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(Theme.accentGradient,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.accentPink.opacity(0.5), radius: 8)
                .padding(14)

            VStack(spacing: 2) {
                Text(Fmt.kcal(remaining))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text("ккал осталось")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text("\(Fmt.kcal(consumed)) / \(Fmt.kcal(goal))")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .frame(width: 186, height: 186)
    }
}

struct MacroColumn: View {
    var title: String
    var consumed: Double
    var goal: Double
    var color: Color

    private var progress: Double { goal > 0 ? consumed / goal : 0 }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {

                Color.clear
                    .frame(width: 66, height: 66)
                    .liquidCircle()
                ProgressRing(progress: progress, color: color, lineWidth: 7)
                    .padding(7)
                Text(Fmt.g(consumed))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
            }
            .frame(width: 66, height: 66)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            Text("\(Fmt.g(consumed)) / \(Fmt.g(goal)) г")
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BigMetricRing: View {
    var title: String
    var valueText: String
    var unit: String
    var caption: String
    var progress: Double
    var color: Color

    var body: some View {
        ZStack {

            Circle()
                .fill(color)
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .opacity(0.45)

            Circle()
                .stroke(Theme.textPrimary.opacity(0.08), lineWidth: 22)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    LinearGradient(colors: [color.opacity(0.7), color],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: 12)
            if progress > 1 {
                Circle()
                    .trim(from: 0, to: min(progress - 1, 1))
                    .stroke(color.opacity(0.5),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(color)
                Text(valueText)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 2)
            }
        }
        .frame(width: 280, height: 280)
    }
}

struct SemiCircleGauge: View {
    var consumed: Double
    var goal: Double
    var burning: Bool = false
    var lineWidth: CGFloat = 18

    @State private var flicker = false

    private let over = Theme.textPrimary

    private var progress: Double { goal > 0 ? min(consumed / goal, 1) : 0 }
    private var remaining: Double { max(goal - consumed, 0) }
    private var overshoot: Double { max(consumed - goal, 0) }
    private var overProgress: Double { goal > 0 ? min(overshoot / goal, 1) : 0 }
    private var hasOvershoot: Bool { overshoot > 0 }

    private var centerValue: String { hasOvershoot ? "+\(Fmt.kcal(overshoot))" : Fmt.kcal(remaining) }
    private var centerLabel: String {
        if hasOvershoot { return "перебор, ккал" }
        return burning ? "цель закрыта" : "осталось, ккал"
    }
    private var accent: Color { hasOvershoot ? over : (burning ? Theme.fire : Theme.accentPink) }

    var body: some View {
        ZStack {
            // Огненная аура (только в режиме закрытого дня)
            if burning {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(hasOvershoot ? over : Theme.fire, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .padding(lineWidth / 2 + 2)
                    .blur(radius: flicker ? 26 : 16)
                    .opacity(flicker ? 0.75 : 0.45)
            }

            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Theme.textPrimary.opacity(0.08),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))

                Circle()
                    .trim(from: 0, to: 0.5 * progress)
                    .stroke(burning ? AnyShapeStyle(Theme.fireGradient) : AnyShapeStyle(Theme.accentGradient),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .shadow(color: (burning ? Theme.fire : Theme.accentPink).opacity(0.5), radius: 8)

                if hasOvershoot {
                    Circle()
                        .trim(from: 0, to: 0.5 * overProgress)
                        .stroke(over, style: StrokeStyle(lineWidth: lineWidth * 0.42, lineCap: .round))
                        .rotationEffect(.degrees(180))
                        .shadow(color: over.opacity(0.6), radius: 6)
                }
            }
            .padding(lineWidth / 2 + 2)

            VStack(spacing: 3) {
                Image(systemName: hasOvershoot ? "exclamationmark.triangle.fill" : "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(accent)
                    .scaleEffect(burning && flicker ? 1.12 : 1)
                Text(centerValue)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text(centerLabel)
                    .font(.caption)
                    .foregroundStyle(burning || hasOvershoot ? accent : Theme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .offset(y: -16)
        }
        .frame(width: 240, height: 240)
        .padding(.bottom, -86)
        .animation(.easeOut(duration: 0.55), value: consumed)
        .onChange(of: burning) { _, on in updateFlicker(on) }
        .onAppear { updateFlicker(burning) }
    }

    private func updateFlicker(_ on: Bool) {
        if on {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { flicker = true }
        } else {
            flicker = false
        }
    }
}

struct MacroBar: View {
    var icon: String
    var title: String
    var consumed: Double
    var goal: Double
    var color: Color

    private var progress: Double { goal > 0 ? min(consumed / goal, 1) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.textPrimary.opacity(0.10))
                    Capsule().fill(color)
                        .frame(width: max(6, geo.size.width * progress))
                }
            }
            .frame(height: 6)

            Text("\(Fmt.g(consumed))/\(Fmt.g(goal)) г")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeOut(duration: 0.55), value: consumed)
    }
}

struct MacroBarWide: View {
    var icon: String
    var title: String
    var consumed: Double
    var goal: Double
    var color: Color
    var burning: Bool = false

    private var progress: Double { goal > 0 ? min(consumed / goal, 1) : 0 }
    private var tint: Color { burning ? Theme.fire : color }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Fmt.g(consumed)) / \(Fmt.g(goal)) г")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.textPrimary.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [tint.opacity(0.7), tint],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * progress))
                        .shadow(color: burning ? Theme.fire.opacity(0.6) : .clear, radius: 6)
                }
            }
            .frame(height: 9)
        }
        .animation(.easeOut(duration: 0.55), value: consumed)
    }
}

struct DateStrip: View {
    @Binding var selected: Date
    @Namespace private var ns
    private let cal = Calendar.current

    private var days: [Date] {
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: selected)
        return Button {
            withAnimation(.snappy(duration: 0.3)) { selected = day }
        } label: {
            VStack(spacing: 4) {
                Text(dayNum(day))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.onAccent : Theme.textPrimary)
                Text(weekday(day))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Theme.onAccent.opacity(0.7) : Theme.textSecondary)
            }
            .frame(width: 38, height: 52)
            .background {
                if isSelected {
                    Capsule().fill(Theme.accentPink)
                        .matchedGeometryEffect(id: "daySelection", in: ns)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pressable)
    }

    private func dayNum(_ d: Date) -> String { "\(cal.component(.day, from: d))" }

    private func weekday(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EE"
        return f.string(from: d).capitalized
    }
}

struct MealCardRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MacroColor.kcal.opacity(0.15))
                Image(systemName: entry.meal.systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(MacroColor.kcal)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(timeString)
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
                HStack(spacing: 6) {
                    pill("\(Fmt.kcal(entry.kcal))", "flame.fill", MacroColor.kcal)
                    pill("\(Fmt.g(entry.protein))", "fish.fill", MacroColor.protein)
                    pill("\(Fmt.g(entry.fat))", "drop.fill", MacroColor.fat)
                    pill("\(Fmt.g(entry.carbs))", "leaf.fill", MacroColor.carbs)
                }
                if !entry.note.isEmpty {
                    Label(entry.note, systemImage: "text.quote")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
    }

    private var timeString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f.string(from: entry.createdAt)
    }

    private func pill(_ text: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.caption2.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14), in: Capsule())
    }
}

struct StreakIndicator: View {
    var days: Int
    var complete: Bool = false

    private var iconColor: Color { complete ? Theme.fire : Theme.blue }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: complete ? "flame.fill" : "flame")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(iconColor)
                .shadow(color: complete ? Theme.fire.opacity(0.7) : .clear, radius: 6)
            Text("\(days)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            Text(days == 1 ? "день" : "дней")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(complete ? Theme.fire.opacity(0.5) : Theme.glassStroke, lineWidth: 1))
    }
}
