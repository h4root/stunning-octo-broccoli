import SwiftUI
import SwiftData

struct DashboardView: View {
    var onEditGoal: () -> Void = {}
    @AppStorage("dashboard.goHome") private var goHome = 0
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private func storeAddDay(_ day: Date) {
        UserDefaults.standard.set(day.timeIntervalSince1970, forKey: "dashboard.addDay")
    }

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
        .onAppear {
            selectedDay = Calendar.current.startOfDay(for: Date())
            storeAddDay(selectedDay)
        }
        .onChange(of: selectedDay) { d in storeAddDay(d) }
        .onChange(of: goHome) { _ in selectedDay = Calendar.current.startOfDay(for: Date()) }
    }
}

private struct DashboardDayContent: View {
    let day: Date
    var onEditGoal: () -> Void
    @EnvironmentObject private var store: Store

    @AppStorage("goal.kcal") private var goalKcal: Double = GoalsDefaults.kcal
    @AppStorage("goal.protein") private var goalProtein: Double = GoalsDefaults.protein
    @AppStorage("goal.fat") private var goalFat: Double = GoalsDefaults.fat
    @AppStorage("goal.carbs") private var goalCarbs: Double = GoalsDefaults.carbs
    @AppStorage("goal.auto") private var autoGoals = true
    @AppStorage("bento.blocks.0") private var bentoRaw = ""

    @State private var editingEntry: FoodEntry?

    private var entries: [FoodEntry] {
        let start = Calendar.current.startOfDay(for: day)
        return store.foodEntries.filter { $0.day == start }.sorted { $0.createdAt > $1.createdAt }
    }
    private var allEntries: [FoodEntry] { store.foodEntries }
    private var customCounters: [CustomCounter] {
        store.customCounters.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var totals: DayTotals { DayTotals(entries: entries) }

    private var dayComplete: Bool { goalKcal > 0 && totals.kcal >= goalKcal }

    var body: some View {
        VStack(spacing: 14) {
            goalRow
            gaugeCard
            macroMosaic
            WaterCard(day: day)
            ForEach(customCounters) { CustomCounterCard(counter: $0, day: day) }
            if !bentoRaw.isEmpty {
                BentoGrid(pageIndex: 0, totals: totals, goalKcal: goalKcal, goalProtein: goalProtein,
                          goalFat: goalFat, goalCarbs: goalCarbs, streak: completedStreak())
            }
            mealsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 130)
        .sheet(item: $editingEntry) { EditEntryView(entry: $0) }
    }

    private var goalRow: some View {
        HStack {
            Button { onEditGoal() } label: {
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
            }
            .buttonStyle(.pressable)

            Spacer()
        }
    }

    private var gaugeCard: some View {
        SemiCircleGauge(consumed: totals.kcal, goal: goalKcal, burning: dayComplete)
            .padding(.top, 8)
            .padding(22)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 28)
    }

    private var macroMosaic: some View {
        HStack(spacing: 12) {
            macroTile("Белки", totals.protein, goalProtein, MacroColor.protein)
            macroTile("Жиры", totals.fat, goalFat, MacroColor.fat)
            macroTile("Углеводы", totals.carbs, goalCarbs, MacroColor.carbs)
        }
    }

    private func macroTile(_ title: String, _ consumed: Double, _ goal: Double, _ color: Color) -> some View {
        MacroColumn(title: title, consumed: consumed, goal: goal, color: color)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: 22)
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
                    Button { editingEntry = entry } label: {
                        MealCardRow(entry: entry)
                    }
                    .buttonStyle(.pressable)
                    .contextMenu {
                        Button { editingEntry = entry } label: { Label("Изменить", systemImage: "pencil") }
                        Button(role: .destructive) {
                            withAnimation { FoodLog.delete(entry, store: store) }
                        } label: { Label("Удалить", systemImage: "trash") }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: entries.count)
    }

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    private func completedStreak() -> Int {
        var perDay: [Date: Double] = [:]
        for e in allEntries { perDay[e.day, default: 0] += e.kcal }
        return CalorieStreak.completed(perDay: perDay, goalKcal: goalKcal)
    }
}
