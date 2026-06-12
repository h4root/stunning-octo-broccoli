import Foundation
import SwiftData

enum WaterTracker {
    static func total(_ logs: [WaterLog]) -> Double { logs.reduce(0) { $0 + $1.ml } }
    static func progress(ml: Double, goal: Double) -> Double { goal > 0 ? min(ml / goal, 1) : 0 }
    static func done(ml: Double, goal: Double) -> Bool { goal > 0 && ml >= goal }

    @discardableResult
    static func add(amount: Double, into logs: [WaterLog], day: Date, context: ModelContext) -> Double {
        let newMl = max(0, total(logs) + amount)
        if let log = logs.first {
            log.ml = newMl
        } else if newMl > 0 {
            context.insert(WaterLog(day: day, ml: newMl))
        }
        return newMl
    }
}
