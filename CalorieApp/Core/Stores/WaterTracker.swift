import Foundation

enum WaterTracker {
    static func total(_ logs: [WaterLog]) -> Double { logs.reduce(0) { $0 + $1.ml } }
    static func progress(ml: Double, goal: Double) -> Double { goal > 0 ? min(ml / goal, 1) : 0 }
    static func done(ml: Double, goal: Double) -> Bool { goal > 0 && ml >= goal }

    @discardableResult
    static func add(amount: Double, into logs: [WaterLog], day: Date, store: Store) -> Double {
        let newMl = max(0, total(logs) + amount)
        store.setWater(day: day, ml: newMl)
        return newMl
    }
}
