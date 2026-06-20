import Foundation
import SwiftData

enum FoodLog {
    @discardableResult
    static func add(_ info: FoodInfo, meal: Meal, grams: Double, note: String, day: Date, context: ModelContext) -> FoodEntry {
        let entry = FoodEntry(
            name: info.name, brand: info.brand, barcode: info.barcode, grams: grams,
            kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
            fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
            saturatedFatPer100: info.saturatedFatPer100,
            meal: meal, day: day, note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            isLiquid: info.isLiquid
        )
        context.insert(entry)
        upsertSaved(info, grams: grams, context: context)
        return entry
    }

    static func upsertSaved(_ info: FoodInfo, grams: Double, context: ModelContext) {
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
            existing.saturatedFatPer100 = info.saturatedFatPer100
            existing.isLiquid = info.isLiquid
        } else {
            let saved = SavedFood(
                name: info.name, brand: info.brand, barcode: info.barcode,
                kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
                fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
                saturatedFatPer100: info.saturatedFatPer100,
                defaultGrams: grams, isLiquid: info.isLiquid
            )
            saved.useCount = 1
            context.insert(saved)
        }
    }

    static func delete(_ entry: FoodEntry, context: ModelContext) {
        context.delete(entry)
    }
}
