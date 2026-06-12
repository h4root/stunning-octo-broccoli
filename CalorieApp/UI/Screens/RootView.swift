import SwiftUI

enum MainTab { case dashboard, activity, beer, profile }

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("fun.beerMeter") private var beerMeter = false
    @AppStorage("profile.name") private var name = ""
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @State private var showOnboarding = false
    @State private var tab: MainTab = .dashboard

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        let base: String
        switch h {
        case 5..<12: base = "Доброе утро"
        case 12..<17: base = "Добрый день"
        case 17..<23: base = "Добрый вечер"
        default: base = "Доброй ночи"
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? base : "\(base), \(trimmed)"
    }

    @State private var showScanner = false
    @State private var showManual = false
    @State private var showSearch = false
    @State private var showGoalPicker = false
    @State private var confirmInfo: FoodInfo?
    @State private var pendingInfo: FoodInfo?
    @State private var manualPrefill: FoodInfo?
    @State private var showBentoAdd = false
    @AppStorage("dashboard.page") private var dashboardPage = 0
    @AppStorage("dashboard.goHome") private var goHome = 0
    @AppStorage("dashboard.addDay") private var addDayStored = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    @State private var lastDashboardTap = Date.distantPast

    private var tabSelection: Binding<MainTab> {
        Binding(
            get: { tab },
            set: { newValue in
                if newValue == .dashboard && tab == .dashboard {
                    let now = Date()
                    if now.timeIntervalSince(lastDashboardTap) < 0.4 {
                        goHome &+= 1
                    }
                    lastDashboardTap = now
                }
                tab = newValue
            }
        )
    }

    @ToolbarContentBuilder
    private var greetingToolbarItem: some ToolbarContent {
        if #available(iOS 26.0, *) {
            ToolbarItem(placement: .topBarLeading) {
                Text(greeting)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Text(greeting)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }

    var body: some View {
        tabs
        .tint(.white)
        .onAppear { showOnboarding = !hasOnboarded }
        .onChange(of: beerMeter) { _, on in
            if on { WaterActivityManager.shared.end() }
            else { BeerActivityManager.shared.end() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && beerMeter {
                BeerActivityManager.shared.reconcileAndSync(context)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { hasOnboarded = true; showOnboarding = false }
        }
        .sheet(isPresented: $showScanner, onDismiss: presentPending) {
            ScannerScreen { info in pendingInfo = info }
        }
        .sheet(isPresented: $showManual, onDismiss: presentPending) {
            ManualFoodView(prefill: manualPrefill) { info in
                manualPrefill = nil; pendingInfo = info
            }
        }
        .sheet(isPresented: $showSearch, onDismiss: presentPending) {
            FoodSearchView { pendingInfo = $0 }
        }
        .sheet(item: $confirmInfo) { ConfirmFoodView(info: $0, day: Date(timeIntervalSince1970: addDayStored)) }
        .sheet(isPresented: $showGoalPicker) { GoalPickerSheet() }
        .sheet(isPresented: $showBentoAdd) { BentoAddSheet(pageIndex: dashboardPage) }
    }

    private var tabs: some View {
        TabView(selection: tabSelection) {
            NavigationStack {
                DashboardView(onEditGoal: { showGoalPicker = true })
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        greetingToolbarItem
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button { showSearch = true } label: {
                                    Label("Поиск по названию", systemImage: "magnifyingglass")
                                }
                                Button { showScanner = true } label: {
                                    Label("По штрихкоду", systemImage: "barcode.viewfinder")
                                }
                                Button { showManual = true } label: {
                                    Label("Вручную", systemImage: "square.and.pencil")
                                }
                                Divider()
                                Button { showBentoAdd = true } label: {
                                    Label("Добавить блок", systemImage: "square.grid.2x2")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem { Label("Главная", systemImage: "house.fill") }
            .tag(MainTab.dashboard)

            NavigationStack {
                ActivityView().navigationTitle("Активность").navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Активность", systemImage: "figure.run") }
            .tag(MainTab.activity)

            if beerMeter {
                NavigationStack {
                    BeerView()
                }
                .tabItem { Label("Пивометр", systemImage: "mug.fill") }
                .tag(MainTab.beer)
            }

            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.fill") }
                .tag(MainTab.profile)
        }
    }

    private func presentPending() {
        guard let info = pendingInfo else { return }
        pendingInfo = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if info.name.isEmpty {
                manualPrefill = info; showManual = true
            } else {
                confirmInfo = info
            }
        }
    }
}

private struct GoalPickerSheet: View {
    @AppStorage("goal.kcal") private var goalKcal = GoalsDefaults.kcal
    @AppStorage("goal.protein") private var goalProtein = GoalsDefaults.protein
    @AppStorage("goal.fat") private var goalFat = GoalsDefaults.fat
    @AppStorage("goal.carbs") private var goalCarbs = GoalsDefaults.carbs
    @AppStorage("goal.auto") private var autoGoals = true

    @AppStorage("profile.sex") private var sexRaw = Sex.male.rawValue
    @AppStorage("profile.age") private var age = 30
    @AppStorage("profile.height") private var heightCm = 175.0
    @AppStorage("profile.weight") private var weightKg = 70.0
    @AppStorage("profile.activity") private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage("profile.goalType") private var goalTypeRaw = GoalType.maintain.rawValue

    @Environment(\.dismiss) private var dismiss

    @State private var selection: Double = 0

    private let kcalValues = Array(stride(from: 800, through: 5000, by: 50))

    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $selection) {
                    Text("Автоматически").tag(0.0)
                    ForEach(kcalValues, id: \.self) { v in
                        Text("\(v) ккал").tag(Double(v))
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppBackground() }
            .navigationTitle("Цель калорий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { apply(); dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                selection = autoGoals ? 0 : (goalKcal / 50).rounded() * 50
            }
        }
        .presentationDetents([.height(320)])
        .presentationBackground(.ultraThinMaterial)
        .preferredColorScheme(.dark)
    }

    private func apply() {
        if selection == 0 {

            autoGoals = true
            let sex = Sex(rawValue: sexRaw) ?? .male
            let activity = ActivityLevel(rawValue: activityRaw) ?? .moderate
            let goalType = GoalType(rawValue: goalTypeRaw) ?? .maintain
            let g = GoalCalculator.goals(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg,
                                         activity: activity, goal: goalType)
            goalKcal = g.kcal; goalProtein = g.protein; goalFat = g.fat; goalCarbs = g.carbs
        } else {
            autoGoals = false
            goalKcal = selection
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [FoodEntry.self, SavedFood.self], inMemory: true)
        .preferredColorScheme(.dark)
}
