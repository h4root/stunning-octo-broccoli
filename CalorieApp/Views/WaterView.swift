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

    private var ml: Double { logs.reduce(0) { $0 + $1.ml } }
    private var progress: Double { goalMl > 0 ? min(ml / goalMl, 1) : 0 }
    private let water = Color(hex: 0x4FC3F7)

    private var done: Bool { goalMl > 0 && ml >= goalMl }

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
                        .fill(LinearGradient(colors: [water.opacity(0.7), water],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * progress))
                        .shadow(color: done ? water.opacity(0.7) : .clear, radius: 6)
                }
            }
            .frame(height: 10)

            HStack(spacing: 10) {
                addButton(250)
                addButton(500)
                Button { add(-250) } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 44, height: 38)
                        .background(Color.white.opacity(0.06), in: Capsule())
                }
                .buttonStyle(.pressable)
                .disabled(ml <= 0)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(water.opacity(done ? 0.55 : 0), lineWidth: 1.5)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: ml)
    }

    private func addButton(_ amount: Double) -> some View {
        Button { add(amount) } label: {
            Text("+\(Fmt.kcal(amount)) мл")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(LinearGradient(colors: [water, water.opacity(0.8)],
                                          startPoint: .top, endPoint: .bottom), in: Capsule())
        }
        .buttonStyle(.pressable)
    }

    private func add(_ amount: Double) {
        let newMl = max(0, ml + amount)
        if let log = logs.first {
            log.ml = newMl
        } else if newMl > 0 {
            context.insert(WaterLog(day: day, ml: newMl))
        }
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
