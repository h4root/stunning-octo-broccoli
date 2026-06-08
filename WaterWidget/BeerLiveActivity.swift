import ActivityKit
import WidgetKit
import SwiftUI

private func beerColor(_ hex: UInt) -> Color {
    if hex == 0 { return Color(red: 0.95, green: 0.66, blue: 0.0) }
    return Color(.sRGB,
                 red: Double((hex >> 16) & 0xFF) / 255,
                 green: Double((hex >> 8) & 0xFF) / 255,
                 blue: Double(hex & 0xFF) / 255,
                 opacity: 1)
}

private let gold = Color(red: 0.95, green: 0.66, blue: 0.0)

struct BeerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BeerActivityAttributes.self) { context in
            BeerLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(gold)
        } dynamicIsland: { context in
            let c = beerColor(context.state.colorHex)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "mug.fill").font(.title3).foregroundStyle(c)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Пиво").font(.caption2).foregroundStyle(.secondary)
                            Text("\(context.state.count) × 0,5")
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                                .contentTransition(.numericText())
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    addButton(size: 38)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.lastBrand.isEmpty ? "Бутылок сегодня" : "Последнее: \(context.state.lastBrand)")
                        .font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "mug.fill").foregroundStyle(c)
            } compactTrailing: {
                Text("\(context.state.count)")
                    .font(.caption2.weight(.bold)).monospacedDigit()
                    .foregroundStyle(gold)
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: "mug.fill").foregroundStyle(gold)
            }
            .keylineTint(gold)
        }
    }
}

private func addButton(size: CGFloat) -> some View {
    Button(intent: AddLastBeerIntent()) {
        Image(systemName: "plus")
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: size, height: size)
            .background(gold, in: Circle())
    }
    .buttonStyle(.plain)
}

private struct BeerLockScreenView: View {
    let state: BeerActivityAttributes.ContentState

    private var c: Color { beerColor(state.colorHex) }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(c.opacity(0.22))
                Image(systemName: "mug.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(c)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(state.count)")
                        .font(.title2.weight(.bold)).monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("× 0,5 л").font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
                Text(state.lastBrand.isEmpty ? "Пивометр" : state.lastBrand)
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            addButton(size: 52)
        }
        .padding(16)
    }
}
