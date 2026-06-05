import ActivityKit
import WidgetKit
import SwiftUI

private let waterColor = Color(red: 0.33, green: 0.78, blue: 0.99)
private let waterGradient = LinearGradient(
    colors: [Color(red: 0.45, green: 0.88, blue: 1.0), Color(red: 0.20, green: 0.62, blue: 0.95)],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private func waterProgress(_ s: WaterActivityAttributes.ContentState) -> Double {
    s.goal > 0 ? min(s.ml / s.goal, 1) : 0
}
private func isDone(_ s: WaterActivityAttributes.ContentState) -> Bool {
    s.goal > 0 && s.ml >= s.goal
}

struct WaterLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaterActivityAttributes.self) { context in
            WaterLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(waterColor)
        } dynamicIsland: { context in
            let p = waterProgress(context.state)
            let done = isDone(context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.body)
                            .foregroundStyle(waterGradient)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Вода").font(.caption2).foregroundStyle(.secondary)
                            Text("\(Int(context.state.ml)) мл")
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                                .contentTransition(.numericText())
                                .lineLimit(1)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Gauge(value: p) {
                        EmptyView()
                    } currentValueLabel: {
                        Text("\(Int(p * 100))").font(.system(size: 12, weight: .bold)).monospacedDigit()
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(waterColor)
                    .frame(width: 38, height: 38)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 5) {
                        ProgressView(value: p)
                            .tint(waterColor)
                        HStack(spacing: 6) {
                            Text("Цель \(Int(context.state.goal)) мл")
                                .font(.caption2).foregroundStyle(.secondary)
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Spacer(minLength: 6)
                            Text(done ? "Выполнено 🎉" : "Осталось \(Int(max(context.state.goal - context.state.ml, 0)))")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(done ? waterColor : .secondary)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: done ? "checkmark.circle.fill" : "drop.fill")
                    .foregroundStyle(waterColor)
            } compactTrailing: {
                Text("\(Int(p * 100))%")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(waterColor)
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: "drop.fill").foregroundStyle(waterColor)
            }
            .keylineTint(waterColor)
        }
    }
}

private struct WaterLockScreenView: View {
    let state: WaterActivityAttributes.ContentState

    private var p: Double { waterProgress(state) }
    private var remaining: Double { max(state.goal - state.ml, 0) }
    private var done: Bool { isDone(state) }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: p)
                    .stroke(waterGradient, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: done ? "checkmark" : "drop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(waterColor)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Вода").font(.headline).foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(p * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(waterColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(state.ml))")
                        .font(.title3.weight(.bold)).monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("/ \(Int(state.goal)) мл")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule().fill(waterGradient)
                            .frame(width: max(6, geo.size.width * p))
                    }
                }
                .frame(height: 7)
                Text(done ? "Цель выполнена 🎉" : "Осталось \(Int(remaining)) мл")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(16)
    }
}
