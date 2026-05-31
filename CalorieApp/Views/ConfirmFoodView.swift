import SwiftUI
import SwiftData

struct NutritionPreview: View {
    var info: FoodInfo
    var grams: Double

    private var f: Double { grams / 100 }

    var body: some View {
        HStack(spacing: 8) {
            cell("Ккал", Fmt.kcal(info.kcalPer100 * f), MacroColor.kcal)
            cell("Белки", Fmt.g(info.proteinPer100 * f), MacroColor.protein)
            cell("Жиры", Fmt.g(info.fatPer100 * f), MacroColor.fat)
            cell("Углев.", Fmt.g(info.carbsPer100 * f), MacroColor.carbs)
        }
    }

    private func cell(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.16))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct DarkFormBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            AppBackground()
            content
                .scrollContentBackground(.hidden)
        }
    }
}

extension View {
    func darkForm() -> some View { modifier(DarkFormBackground()) }
}

struct ConfirmFoodView: View {
    let info: FoodInfo
    var initialMeal: Meal = Meal.suggestedForNow()
    var day: Date = Date()

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var grams: Double
    @State private var meal: Meal
    @State private var gramsText: String

    init(info: FoodInfo, initialMeal: Meal = Meal.suggestedForNow(), day: Date = Date()) {
        self.info = info
        self.initialMeal = initialMeal
        self.day = day
        _grams = State(initialValue: info.defaultGrams)
        _meal = State(initialValue: initialMeal)
        _gramsText = State(initialValue: Fmt.kcal(info.defaultGrams))
    }

    private let presets: [Double] = [30, 50, 100, 150, 200, 250]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.name).font(.headline).foregroundStyle(Theme.textPrimary)
                        if let brand = info.brand {
                            Text(brand).font(.subheadline).foregroundStyle(Theme.textSecondary)
                        }
                        if let bc = info.barcode {
                            Label(bc, systemImage: "barcode").font(.caption).foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
                .listRowBackground(Theme.glassFill)

                Section {
                    Picker("Приём пищи", selection: $meal) {
                        ForEach(Meal.allCases) { m in Text(m.title).tag(m) }
                    }
                    .pickerStyle(.segmented)
                } header: { sectionHeader("Приём пищи") }
                .listRowBackground(Theme.glassFill)

                Section {
                    HStack {
                        TextField("Граммы", text: $gramsText)
                            .keyboardType(.decimalPad)
                            .onChange(of: gramsText) { _, v in
                                grams = Double(v.replacingOccurrences(of: ",", with: ".")) ?? 0
                            }
                        Text("г").foregroundStyle(Theme.textSecondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { p in
                                GramChip(grams: p, isSelected: abs(grams - p) < 0.5) {
                                    grams = p; gramsText = Fmt.kcal(p)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: { sectionHeader("Количество") }
                .listRowBackground(Theme.glassFill)

                Section {
                    NutritionPreview(info: info, grams: grams)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                } header: { sectionHeader("На вашу порцию") }
                .listRowBackground(Color.clear)

                Section {
                    nutrientRow("Калории", "\(Fmt.kcal(info.kcalPer100)) ккал")
                    nutrientRow("Белки", "\(Fmt.g(info.proteinPer100)) г")
                    nutrientRow("Жиры", "\(Fmt.g(info.fatPer100)) г")
                    nutrientRow("Углеводы", "\(Fmt.g(info.carbsPer100)) г")
                } header: { sectionHeader("На 100 г") }
                .listRowBackground(Theme.glassFill)
            }
            .darkForm()
            .navigationTitle("Добавить продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { add() }.fontWeight(.semibold).disabled(grams <= 0)
                }
            }
        }
    }

    private func add() {
        let entry = FoodEntry(
            name: info.name, brand: info.brand, barcode: info.barcode, grams: grams,
            kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
            fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
            meal: meal, day: day
        )
        context.insert(entry)
        upsertSavedFood()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func upsertSavedFood() {
        let bc = info.barcode
        let name = info.name
        var descriptor = FetchDescriptor<SavedFood>()
        descriptor.predicate = #Predicate { food in
            (bc != nil && food.barcode == bc) || (food.barcode == nil && food.name == name)
        }
        if let existing = try? context.fetch(descriptor).first {
            existing.lastUsed = Date()
            existing.useCount += 1
            existing.defaultGrams = grams
            existing.kcalPer100 = info.kcalPer100
            existing.proteinPer100 = info.proteinPer100
            existing.fatPer100 = info.fatPer100
            existing.carbsPer100 = info.carbsPer100
        } else {
            let saved = SavedFood(
                name: info.name, brand: info.brand, barcode: info.barcode,
                kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
                fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
                defaultGrams: grams
            )
            saved.useCount = 1
            context.insert(saved)
        }
    }
}

struct EditEntryView: View {
    @Bindable var entry: FoodEntry
    @Environment(\.dismiss) private var dismiss

    @State private var gramsText: String = ""
    private let presets: [Double] = [30, 50, 100, 150, 200, 250]

    private var info: FoodInfo {
        FoodInfo(name: entry.name, brand: entry.brand, barcode: entry.barcode,
                 kcalPer100: entry.kcalPer100, proteinPer100: entry.proteinPer100,
                 fatPer100: entry.fatPer100, carbsPer100: entry.carbsPer100)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(entry.name).font(.headline).foregroundStyle(Theme.textPrimary)
                    if let brand = entry.brand {
                        Text(brand).font(.subheadline).foregroundStyle(Theme.textSecondary)
                    }
                }
                .listRowBackground(Theme.glassFill)

                Section {
                    Picker("Приём пищи", selection: $entry.meal) {
                        ForEach(Meal.allCases) { m in Text(m.title).tag(m) }
                    }
                    .pickerStyle(.segmented)
                } header: { sectionHeader("Приём пищи") }
                .listRowBackground(Theme.glassFill)

                Section {
                    HStack {
                        TextField("Граммы", text: $gramsText)
                            .keyboardType(.decimalPad)
                            .onChange(of: gramsText) { _, v in
                                entry.grams = Double(v.replacingOccurrences(of: ",", with: ".")) ?? 0
                            }
                        Text("г").foregroundStyle(Theme.textSecondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { p in
                                GramChip(grams: p, isSelected: abs(entry.grams - p) < 0.5) {
                                    entry.grams = p; gramsText = Fmt.kcal(p)
                                }
                            }
                        }
                    }
                } header: { sectionHeader("Количество") }
                .listRowBackground(Theme.glassFill)

                Section {
                    NutritionPreview(info: info, grams: entry.grams)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                } header: { sectionHeader("На вашу порцию") }
                .listRowBackground(Color.clear)
            }
            .darkForm()
            .navigationTitle("Изменить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear { gramsText = Fmt.kcal(entry.grams) }
        }
    }
}

func sectionHeader(_ text: String) -> some View {
    Text(text).foregroundStyle(Theme.textSecondary)
}

func nutrientRow(_ title: String, _ value: String) -> some View {
    HStack {
        Text(title).foregroundStyle(Theme.textPrimary)
        Spacer()
        Text(value).foregroundStyle(Theme.textSecondary)
    }
}

extension Meal {
    static func suggestedForNow() -> Meal {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
}
