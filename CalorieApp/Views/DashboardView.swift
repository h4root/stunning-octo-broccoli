import SwiftUI
import SwiftData

struct DashboardView: View {
    var onEditGoal: () -> Void = {}
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 0) {
                    DateStrip(selected: $selectedDay)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    DashboardDayContent(day: selectedDay, onEditGoal: onEditGoal)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct DashboardDayContent: View {
    let day: Date
    var onEditGoal: () -> Void
    @Query private var entries: [FoodEntry]
    @Query(sort: \FoodEntry.day, order: .reverse) private var allEntries: [FoodEntry]
    @Environment(\.modelContext) private var context

    @AppStorage("goal.kcal") private var goalKcal: Double = GoalsDefaults.kcal
    @AppStorage("goal.protein") private var goalProtein: Double = GoalsDefaults.protein
    @AppStorage("goal.fat") private var goalFat: Double = GoalsDefaults.fat
    @AppStorage("goal.carbs") private var goalCarbs: Double = GoalsDefaults.carbs
    @AppStorage("goal.auto") private var autoGoals = true

    @State private var editingEntry: FoodEntry?

    init(day: Date, onEditGoal: @escaping () -> Void) {
        self.day = day
        self.onEditGoal = onEditGoal
        let start = Calendar.current.startOfDay(for: day)
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.day == start },
            sort: \FoodEntry.createdAt, order: .reverse
        )
    }

    private var totals: DayTotals { DayTotals(entries: entries) }

    var body: some View {
        VStack(spacing: 18) {
            goalRow
            summaryCard
            mealsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 130)
        .sheet(item: $editingEntry) { EditEntryView(entry: $0) }
    }

    private var goalRow: some View {
        HStack {
            HStack(spacing: 4) {
                Text("Цель:")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Text(autoGoals ? "Авто" : "\(Fmt.kcal(goalKcal)) ккал")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.accentPink)
                    .monospacedDigit()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Theme.glassStroke, lineWidth: 1))
            .contentShape(Capsule())
            .onTapGesture { onEditGoal() }

            Spacer()

            StreakIndicator(days: streakDays())
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 20) {
            SemiCircleGauge(consumed: totals.kcal, goal: goalKcal)
                .padding(.top, 8)

            VStack(spacing: 16) {
                MacroBarWide(icon: "fish.fill", title: "Белки", consumed: totals.protein, goal: goalProtein, color: MacroColor.protein)
                MacroBarWide(icon: "drop.fill", title: "Жиры", consumed: totals.fat, goal: goalFat, color: MacroColor.fat)
                MacroBarWide(icon: "leaf.fill", title: "Углеводы", consumed: totals.carbs, goal: goalCarbs, color: MacroColor.carbs)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isToday ? "Сегодняшние приёмы" : "Приёмы пищи")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.textTertiary)
                    Text("Пока ничего не добавлено")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .glassCard(cornerRadius: 18)
            } else {
                ForEach(entries) { entry in
                    MealCardRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture { editingEntry = entry }
                        .contextMenu {
                            Button { editingEntry = entry } label: { Label("Изменить", systemImage: "pencil") }
                            Button(role: .destructive) {
                                withAnimation { context.delete(entry) }
                            } label: { Label("Удалить", systemImage: "trash") }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: entries.count)
    }

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private func streakDays() -> Int {
        let cal = Calendar.current
        let days = Set(allEntries.map { $0.day })
        var d = cal.startOfDay(for: Date())
        if !days.contains(d) {
            guard let y = cal.date(byAdding: .day, value: -1, to: d), days.contains(y) else { return 0 }
            d = y
        }
        var streak = 0
        while days.contains(d) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return streak
    }
}
