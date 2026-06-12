import Foundation
import SwiftData

enum BeerTracker {
    static let bottleMl: Double = 500

    static func today(_ logs: [BeerLog], on day: Date) -> [BeerLog] { logs.filter { $0.day == day } }
    static func totalMl(_ logs: [BeerLog]) -> Double { logs.reduce(0) { $0 + $1.ml } }
    static func bottles(_ logs: [BeerLog]) -> Double { totalMl(logs) / bottleMl }
    static func liters(_ logs: [BeerLog]) -> Double { totalMl(logs) / 1000 }
    static func kcal(_ logs: [BeerLog]) -> Double { logs.reduce(0) { $0 + $1.ml * 0.43 } }
    static func alcoholGrams(_ logs: [BeerLog]) -> Double { logs.reduce(0) { $0 + $1.alcoholGrams } }

    static func promille(alcoholGrams: Double, weightKg: Double, sex: String) -> Double {
        let r = (sex == "female") ? 0.6 : 0.7
        guard weightKg > 0 else { return 0 }
        return max(0, alcoholGrams / (weightKg * r))
    }

    static func streak(days: Set<Date>, today: Date) -> Int {
        var count = 0
        var cursor = today
        let cal = Calendar.current
        while days.contains(cursor) {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return count
    }

    @discardableResult
    static func add(_ beer: Beer, day: Date, context: ModelContext) -> BeerLog {
        let log = BeerLog(day: day, brand: beer.name, ml: bottleMl, abv: beer.abv)
        context.insert(log)
        return log
    }

    @discardableResult
    static func remove(brand: String, from logs: [BeerLog], context: ModelContext) -> BeerLog? {
        guard let log = logs.first(where: { $0.brand == brand }) else { return nil }
        context.delete(log)
        return log
    }
}
