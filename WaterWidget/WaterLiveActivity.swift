import ActivityKit
import WidgetKit
import SwiftUI

private func waterProgress(_ s: WaterActivityAttributes.ContentState) -> Double {
    s.goal > 0 ? min(s.ml / s.goal, 1) : 0
}

private let waterColor = Color(red: 0.31, green: 0.76, blue: 0.97)

struct WaterLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WaterActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(waterColor)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Вода").font(.headline)
                    ProgressView(value: waterProgress(context.state)).tint(waterColor)
                }
                Text("\(Int(context.state.ml))/\(Int(context.state.goal)) мл")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.6))
            .activitySystemActionForegroundColor(waterColor)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Вода", systemImage: "drop.fill")
                        .foregroundStyle(waterColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.ml))/\(Int(context.state.goal)) мл")
                        .font(.caption).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: waterProgress(context.state)).tint(waterColor)
                }
            } compactLeading: {
                Image(systemName: "drop.fill").foregroundStyle(waterColor)
            } compactTrailing: {
                Text("\(Int(waterProgress(context.state) * 100))%")
                    .font(.caption2).monospacedDigit()
            } minimal: {
                Image(systemName: "drop.fill").foregroundStyle(waterColor)
            }
        }
    }
}
