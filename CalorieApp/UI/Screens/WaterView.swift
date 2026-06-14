import SwiftUI
import SwiftData

struct WaterCard: View {
    let day: Date
    @Environment(\.modelContext) private var context
    @Query private var logs: [WaterLog]
    @AppStorage("goal.water") private var goalMl: Double = 2000
    @AppStorage("fun.beerMeter") private var beerMeter = false

    init(day: Date) {
        self.day = day
        let start = Calendar.current.startOfDay(for: day)
        _logs = Query(filter: #Predicate<WaterLog> { $0.day == start })
    }

    private var ml: Double { WaterTracker.total(logs) }
    private var progress: Double { WaterTracker.progress(ml: ml, goal: goalMl) }
    private let water = Theme.textPrimary

    private var done: Bool { WaterTracker.done(ml: ml, goal: goalMl) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: done ? "checkmark.circle.fill" : "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(water)
                    .symbolEffect(.bounce, value: ml)
                    .contentTransition(.symbolEffect(.replace))
                Text("Вода").font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Fmt.kcal(ml)) / \(Fmt.kcal(goalMl)) мл")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(done ? AnyShapeStyle(Theme.acid) : AnyShapeStyle(LinearGradient(colors: [water.opacity(0.55), water],
                                             startPoint: .leading, endPoint: .trailing)))
                        .frame(width: max(8, geo.size.width * progress))
                        .shadow(color: done ? Theme.acid.opacity(0.7) : .clear, radius: 6)
                }
            }
            .frame(height: 10)

            HStack(spacing: 10) {
                Spacer()
                Button { add(-250) } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 46, height: 40)
                        .background(Color.white.opacity(0.06), in: Capsule())
                }
                .buttonStyle(.pressable)
                .disabled(ml <= 0)
                Button { add(250) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.onAccent)
                        .frame(width: 56, height: 40)
                        .background(Theme.acid, in: Capsule())
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.acid.opacity(done ? 0.55 : 0), lineWidth: 1.5)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: ml)
    }

    private func add(_ amount: Double) {
        let newMl = WaterTracker.add(amount: amount, into: logs, day: day, context: context)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if Calendar.current.isDateInToday(day) {
            if beerMeter {
                WaterActivityManager.shared.end()
            } else {
                WaterActivityManager.shared.update(ml: newMl, goal: goalMl)
            }
        }
    }
}
