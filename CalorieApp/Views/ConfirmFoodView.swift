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

struct GramsRow: View {
    @Binding var grams: Double
    var unit: String = "г"
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            HStack {
                Text("Количество").foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Fmt.kcal(grams)) \(unit)")
                    .foregroundStyle(Theme.accentPink)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accentPink)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $show) { GramsPickerSheet(grams: $grams, unit: unit) }
    }
}

private struct GramsPickerSheet: View {
    @Binding var grams: Double
    var unit: String = "г"
    @Environment(\.dismiss) private var dismiss

    private var maxGrams: Int { max(1000, Int(grams.rounded())) }

    var body: some View {
        NavigationStack {
            Picker("", selection: Binding(
                get: { min(max(Int(grams.rounded()), 1), maxGrams) },
                set: { grams = Double($0) }
            )) {
                ForEach(1...maxGrams, id: \.self) { Text("\($0) \(unit)").tag($0) }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { AppBackground() }
            .navigationTitle("Количество")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationBackground(.ultraThinMaterial)
        .preferredColorScheme(.dark)
    }
}

struct ConfirmFoodView: View {
    let info: FoodInfo
    var initialMeal: Meal = Meal.suggestedForNow()
    var day: Date = Date()

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var grams: Double
    @State private var meal: Meal
    @State private var note: String = ""

    init(info: FoodInfo, initialMeal: Meal = Meal.suggestedForNow(), day: Date = Date()) {
        self.info = info
        self.initialMeal = initialMeal
        self.day = day
        _grams = State(initialValue: info.defaultGrams)
        _meal = State(initialValue: initialMeal)
    }

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
                    GramsRow(grams: $grams, unit: info.isLiquid ? "мл" : "г")
                } header: { sectionHeader("Количество") }
                .listRowBackground(Theme.glassFill)

                Section {
                    NutritionPreview(info: info, grams: grams)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                } header: { sectionHeader("На вашу порцию") }
                .listRowBackground(Color.clear)

                Section {
                    TextField("Например: без сахара", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .foregroundStyle(Theme.textPrimary)
                } header: { sectionHeader("Заметка") }
                .listRowBackground(Theme.glassFill)

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
            meal: meal, day: day, note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            isLiquid: info.isLiquid
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
            existing.isLiquid = info.isLiquid
        } else {
            let saved = SavedFood(
                name: info.name, brand: info.brand, barcode: info.barcode,
                kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
                fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
                defaultGrams: grams, isLiquid: info.isLiquid
            )
            saved.useCount = 1
            context.insert(saved)
        }
    }
}

struct EditEntryView: View {
    @Bindable var entry: FoodEntry
    @Environment(\.dismiss) private var dismiss

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
                    GramsRow(grams: $entry.grams, unit: entry.unit)
                } header: { sectionHeader("Количество") }
                .listRowBackground(Theme.glassFill)

                Section {
                    NutritionPreview(info: info, grams: entry.grams)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                } header: { sectionHeader("На вашу порцию") }
                .listRowBackground(Color.clear)

                Section {
                    TextField("Например: без сахара", text: $entry.note, axis: .vertical)
                        .lineLimit(1...3)
                        .foregroundStyle(Theme.textPrimary)
                } header: { sectionHeader("Заметка") }
                .listRowBackground(Theme.glassFill)
            }
            .darkForm()
            .navigationTitle("Изменить")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
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
