import Foundation

enum FoodLog {
    @discardableResult
    static func add(_ info: FoodInfo, meal: Meal, grams: Double, note: String, day: Date, store: Store) -> FoodEntry {
        let entry = FoodEntry(
            name: info.name, brand: info.brand, barcode: info.barcode, grams: grams,
            kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
            fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
            meal: meal, day: day, note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            isLiquid: info.isLiquid
        )
        store.addFood(entry)
        store.upsertSaved(info, grams: grams)
        return entry
    }

    static func delete(_ entry: FoodEntry, store: Store) {
        store.deleteFood(entry)
    }
}
