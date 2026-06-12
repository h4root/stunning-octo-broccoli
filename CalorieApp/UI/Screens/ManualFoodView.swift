import SwiftUI

struct ManualFoodView: View {
    var prefill: FoodInfo?
    var onComplete: (FoodInfo) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var barcode = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var fat = ""
    @State private var carbs = ""

    init(prefill: FoodInfo? = nil, onComplete: @escaping (FoodInfo) -> Void) {
        self.prefill = prefill
        self.onComplete = onComplete
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && num(kcal) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: $name)
                    TextField("Бренд (необязательно)", text: $brand)
                    TextField("Штрихкод (необязательно)", text: $barcode)
                        .keyboardType(.numberPad)
                } header: { sectionHeader("Продукт") }
                .listRowBackground(Theme.glassFill)

                Section {
                    macroField("Калории, ккал", text: $kcal)
                    macroField("Белки, г", text: $protein)
                    macroField("Жиры, г", text: $fat)
                    macroField("Углеводы, г", text: $carbs)
                } header: { sectionHeader("Пищевая ценность на 100 г") }
                .listRowBackground(Theme.glassFill)
            }
            .darkForm()
            .navigationTitle("Новый продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Далее") { submit() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: applyPrefill)
        }
    }

    private func macroField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.textPrimary)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
    }

    private func applyPrefill() {
        guard let p = prefill else { return }
        if name.isEmpty { name = p.name }
        if brand.isEmpty { brand = p.brand ?? "" }
        if barcode.isEmpty { barcode = p.barcode ?? "" }
    }

    private func num(_ s: String) -> Double? {
        Double(s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }

    private func submit() {
        let info = FoodInfo(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces).isEmpty ? nil : brand,
            barcode: barcode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : barcode,
            kcalPer100: num(kcal) ?? 0,
            proteinPer100: num(protein) ?? 0,
            fatPer100: num(fat) ?? 0,
            carbsPer100: num(carbs) ?? 0
        )
        onComplete(info)
        dismiss()
    }
}
