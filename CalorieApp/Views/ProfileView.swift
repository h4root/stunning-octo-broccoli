import SwiftUI

private enum ProfileField: String, Identifiable {
    case age, height, weight
    var id: String { rawValue }

    var title: String {
        switch self {
        case .age: return "Возраст"
        case .height: return "Рост"
        case .weight: return "Вес"
        }
    }
}

struct ProfileView: View {
    @AppStorage("profile.name") private var name = ""
    @AppStorage("profile.sex") private var sexRaw = Sex.male.rawValue
    @AppStorage("profile.age") private var age = 30
    @AppStorage("profile.height") private var heightCm = 175.0
    @AppStorage("profile.weight") private var weightKg = 70.0
    @AppStorage("profile.activity") private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage("profile.goalType") private var goalTypeRaw = GoalType.maintain.rawValue
    @AppStorage("goal.auto") private var autoGoals = true

    @AppStorage("goal.kcal") private var goalKcal = GoalsDefaults.kcal
    @AppStorage("goal.protein") private var goalProtein = GoalsDefaults.protein
    @AppStorage("goal.fat") private var goalFat = GoalsDefaults.fat
    @AppStorage("goal.carbs") private var goalCarbs = GoalsDefaults.carbs

    @State private var editing: ProfileField?

    private var sex: Sex { Sex(rawValue: sexRaw) ?? .male }
    private var activity: ActivityLevel { ActivityLevel(rawValue: activityRaw) ?? .moderate }
    private var goalType: GoalType { GoalType(rawValue: goalTypeRaw) ?? .maintain }
    private var rowBackground: some View { Rectangle().fill(.ultraThinMaterial) }

    private var computed: DailyGoals {
        GoalCalculator.goals(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg,
                             activity: activity, goal: goalType)
    }

    var body: some View {
        NavigationStack {
            Form {
                aboutSection
                bodySection
                activitySection
                goalSection
                targetsSection
                resetSection
            }
            .darkForm()
            .contentMargins(.bottom, 110, for: .scrollContent)
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(item: $editing) { MetricPickerSheet(field: $0) }
            .onChange(of: sexRaw) { _, _ in recalc() }
            .onChange(of: age) { _, _ in recalc() }
            .onChange(of: heightCm) { _, _ in recalc() }
            .onChange(of: weightKg) { _, _ in recalc() }
            .onChange(of: activityRaw) { _, _ in recalc() }
            .onChange(of: goalTypeRaw) { _, _ in recalc() }
            .onChange(of: autoGoals) { _, on in if on { recalc() } }
            .onAppear { recalc() }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Имя").foregroundStyle(Theme.textPrimary)
                Spacer()
                TextField("Ваше имя", text: $name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.accentPink)
                    .fontWeight(.semibold)
            }
        } header: { sectionHeader("О вас") }
        .listRowBackground(rowBackground)
    }

    private var bodySection: some View {
        Section {
            Picker("Пол", selection: Binding(get: { sex }, set: { sexRaw = $0.rawValue })) {
                ForEach(Sex.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            pickerRow(.age, value: "\(age) лет")
            pickerRow(.height, value: "\(Fmt.kcal(heightCm)) см")
            pickerRow(.weight, value: "\(Fmt.kcal(weightKg)) кг")

            if HealthService.shared.isAvailable {
                Button {
                    Task {
                        let h = HealthService.shared
                        if !h.didRequest { await h.requestAuthorization() }
                        if let w = await h.fetchLatestWeight() { weightKg = w.rounded() }
                    }
                } label: {
                    Label("Взять вес из Apple Health", systemImage: "heart.fill")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accentPink)
                }
            }
        } header: { sectionHeader("Параметры тела") }
        .listRowBackground(rowBackground)
    }

    private func pickerRow(_ field: ProfileField, value: String) -> some View {
        Button { editing = field } label: {
            HStack {
                Text(field.title).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(value)
                    .foregroundStyle(Theme.accentPink)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accentPink)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var activitySection: some View {
        Section {
            Picker("Активность", selection: Binding(get: { activity }, set: { activityRaw = $0.rawValue })) {
                ForEach(ActivityLevel.allCases) { Text($0.title).tag($0) }
            }
            .tint(Theme.accentPink)
        } header: {
            sectionHeader("Активность")
        } footer: {
            Text(activity.subtitle).foregroundStyle(Theme.textTertiary)
        }
        .listRowBackground(rowBackground)
    }

    private var goalSection: some View {
        Section {
            Picker("Цель", selection: Binding(get: { goalType }, set: { goalTypeRaw = $0.rawValue })) {
                ForEach(GoalType.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
        } header: { sectionHeader("Цель") }
        .listRowBackground(rowBackground)
    }

    private var targetsSection: some View {
        Section {
            Toggle("Авто-расчёт КБЖУ", isOn: $autoGoals)
                .tint(Theme.accentPink)
                .foregroundStyle(Theme.textPrimary)

            if autoGoals {
                nutrientRow("Калории", "\(Fmt.kcal(goalKcal)) ккал")
                nutrientRow("Белки", "\(Fmt.g(goalProtein)) г")
                nutrientRow("Жиры", "\(Fmt.g(goalFat)) г")
                nutrientRow("Углеводы", "\(Fmt.g(goalCarbs)) г")
            } else {
                GoalRow(title: "Калории", unit: "ккал", value: $goalKcal, color: MacroColor.kcal, step: 50)
                GoalRow(title: "Белки", unit: "г", value: $goalProtein, color: MacroColor.protein, step: 5)
                GoalRow(title: "Жиры", unit: "г", value: $goalFat, color: MacroColor.fat, step: 5)
                GoalRow(title: "Углеводы", unit: "г", value: $goalCarbs, color: MacroColor.carbs, step: 5)
            }
        } header: {
            sectionHeader("Дневные цели")
        } footer: {
            Text(autoGoals
                 ? "Считается по формуле Mifflin–St Jeor с учётом активности и цели. Выключите тумблер, чтобы задать вручную."
                 : "Ручной режим. Включите тумблер для авто-расчёта по параметрам тела.")
            .foregroundStyle(Theme.textTertiary)
        }
        .listRowBackground(rowBackground)
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                goalKcal = GoalsDefaults.kcal
                goalProtein = GoalsDefaults.protein
                goalFat = GoalsDefaults.fat
                goalCarbs = GoalsDefaults.carbs
                autoGoals = false
            } label: {
                Text("Сбросить макросы по умолчанию")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.red)
            }
        }
        .listRowBackground(rowBackground)
    }

    private func recalc() {
        guard autoGoals else { return }
        let g = computed
        goalKcal = g.kcal; goalProtein = g.protein; goalFat = g.fat; goalCarbs = g.carbs
    }
}

private struct MetricPickerSheet: View {
    let field: ProfileField
    @AppStorage("profile.age") private var age = 30
    @AppStorage("profile.height") private var heightCm = 175.0
    @AppStorage("profile.weight") private var weightKg = 70.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                switch field {
                case .age:
                    Picker("", selection: $age) {
                        ForEach(10...100, id: \.self) { Text("\($0) лет").tag($0) }
                    }.pickerStyle(.wheel).labelsHidden()
                case .height:
                    Picker("", selection: $heightCm) {
                        ForEach(120...220, id: \.self) { Text("\($0) см").tag(Double($0)) }
                    }.pickerStyle(.wheel).labelsHidden()
                case .weight:
                    Picker("", selection: $weightKg) {
                        ForEach(30...250, id: \.self) { Text("\($0) кг").tag(Double($0)) }
                    }.pickerStyle(.wheel).labelsHidden()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppBackground() }
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear {

                heightCm = heightCm.rounded()
                weightKg = weightKg.rounded()
            }
        }
        .presentationDetents([.height(300)])
        .presentationBackground(.ultraThinMaterial)
        .preferredColorScheme(.dark)
    }
}

struct GoalRow: View {
    let title: String
    let unit: String
    @Binding var value: Double
    let color: Color
    let step: Double

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title).foregroundStyle(Theme.textPrimary)
            Spacer()
            Stepper(value: $value, in: 0...10000, step: step) {
                Text("\(Fmt.kcal(value)) \(unit)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
            .fixedSize()
        }
    }
}

#Preview {
    ProfileView().preferredColorScheme(.dark)
}
