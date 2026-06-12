import SwiftUI
import SwiftData

struct DashboardView: View {
    var onEditGoal: () -> Void = {}
    @AppStorage("dashboard.pageCount") private var pageCount = 1
    @AppStorage("dashboard.page") private var storedPage = 0
    @AppStorage("dashboard.goHome") private var goHome = 0
    @State private var scrollID: Int? = 0
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())

    private func storeAddDay(_ day: Date) {
        UserDefaults.standard.set(day.timeIntervalSince1970, forKey: "dashboard.addDay")
    }

    private var pageBinding: Binding<Int> {
        Binding(get: { scrollID ?? 0 }, set: { scrollID = $0 })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    page0
                        .containerRelativeFrame(.horizontal)
                        .id(0)
                    ForEach(Array(1..<max(pageCount, 1)), id: \.self) { i in
                        ExtraDashboardPage(index: i)
                            .containerRelativeFrame(.horizontal)
                            .id(i)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollID)
            .scrollIndicators(.hidden)

            DashboardPageDots(page: pageBinding, pageCount: $pageCount)
                .padding(.bottom, 10)
        }
        .onAppear {
            scrollID = min(storedPage, max(pageCount - 1, 0))
            selectedDay = Calendar.current.startOfDay(for: Date())
            storeAddDay(selectedDay)
        }
        .onChange(of: selectedDay) { _, d in storeAddDay(d) }
        .onChange(of: scrollID) { _, p in if let p { storedPage = p } }
        .onChange(of: goHome) { _, _ in
            if (scrollID ?? 0) != 0 { scrollID = 0 }
        }
        .onChange(of: pageCount) { _, c in if (scrollID ?? 0) > c - 1 { scrollID = max(c - 1, 0) } }
    }

    private var page0: some View {
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

private struct DashboardPageDots: View {
    @Binding var page: Int
    @Binding var pageCount: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accentPink : Color.white.opacity(0.28))
                    .frame(width: 7, height: 7)
                    .onTapGesture { page = i }
                    .onLongPressGesture {
                        if i == pageCount - 1 && i > 0 { removeLast() }
                    }
            }
            if pageCount < 3 {
                Button {
                    pageCount += 1
                    page = pageCount - 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 16, height: 16)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.glassStroke, lineWidth: 1))
    }

    private func removeLast() {
        guard pageCount > 1 else { return }
        UserDefaults.standard.removeObject(forKey: bentoKey(pageCount - 1))
        pageCount -= 1
        if page > pageCount - 1 { page = pageCount - 1 }
    }
}

private struct ExtraDashboardPage: View {
    let index: Int
    @Query private var entries: [FoodEntry]
    @Query(sort: \FoodEntry.day, order: .reverse) private var allEntries: [FoodEntry]

    @AppStorage("goal.kcal") private var goalKcal: Double = GoalsDefaults.kcal
    @AppStorage("goal.protein") private var goalProtein: Double = GoalsDefaults.protein
    @AppStorage("goal.fat") private var goalFat: Double = GoalsDefaults.fat
    @AppStorage("goal.carbs") private var goalCarbs: Double = GoalsDefaults.carbs
    @AppStorage private var bentoRaw: String

    init(index: Int) {
        self.index = index
        let start = Calendar.current.startOfDay(for: Date())
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.day == start },
            sort: \FoodEntry.createdAt, order: .reverse
        )
        _bentoRaw = AppStorage(wrappedValue: "", bentoKey(index))
    }

    private var totals: DayTotals { DayTotals(entries: entries) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if bentoRaw.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 30))
                            .foregroundStyle(Theme.textTertiary)
                        Text("Пустой экран")
                            .font(.headline)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Нажмите «+» → «Добавить блок»")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .glassCard(cornerRadius: 20)
                } else {
                    BentoGrid(pageIndex: index, totals: totals, goalKcal: goalKcal,
                              goalProtein: goalProtein, goalFat: goalFat, goalCarbs: goalCarbs,
                              streak: computeStreak(days: Set(allEntries.map { $0.day })))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 130)
        }
        .scrollIndicators(.hidden)
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
    @AppStorage("bento.blocks.0") private var bentoRaw = ""

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

    private var dayComplete: Bool { goalKcal > 0 && totals.kcal >= goalKcal }

    var body: some View {
        VStack(spacing: 14) {
            goalRow
            gaugeCard
            macroMosaic
            WaterCard(day: day)
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

            StreakIndicator(days: completedStreak(), complete: dayComplete)
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
                            withAnimation { FoodLog.delete(entry, context: context) }
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
