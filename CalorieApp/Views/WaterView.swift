import SwiftUI
import SwiftData

struct WaterCard: View {
    let day: Date
    @Environment(\.modelContext) private var context
    @Query private var logs: [WaterLog]
    @AppStorage("goal.water") private var goalMl: Double = 2000

    init(day: Date) {
        self.day = day
        let start = Calendar.current.startOfDay(for: day)
        _logs = Query(filter: #Predicate<WaterLog> { $0.day == start })
    }

    private var ml: Double { logs.reduce(0) { $0 + $1.ml } }
    private var progress: Double { goalMl > 0 ? min(ml / goalMl, 1) : 0 }
    private let water = Color(hex: 0x4FC3F7)

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(water)
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
        .animation(.easeOut(duration: 0.4), value: ml)
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
        if let log = logs.first {
            log.ml = max(0, log.ml + amount)
        } else if amount > 0 {
            context.insert(WaterLog(day: day, ml: amount))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if Calendar.current.isDateInToday(day) {
            WaterActivityManager.shared.update(ml: max(0, ml), goal: goalMl)
        }
    }
}
