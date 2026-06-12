import Foundation
import SwiftData

enum CustomCounterStore {
    static func value(_ logs: [CustomCounterLog]) -> Double { logs.first?.value ?? 0 }
    static func progress(value: Double, goal: Double) -> Double { goal > 0 ? min(value / goal, 1) : 0 }
    static func done(value: Double, goal: Double) -> Bool { goal > 0 && value >= goal }

    @discardableResult
    static func add(amount: Double, counterID: UUID, into logs: [CustomCounterLog], day: Date, context: ModelContext) -> Double {
        let newValue = max(0, value(logs) + amount)
        if let log = logs.first {
            log.value = newValue
        } else if newValue > 0 {
            context.insert(CustomCounterLog(counterID: counterID, day: day, value: newValue))
        }
        return newValue
    }

    static func delete(_ counter: CustomCounter, context: ModelContext) {
        let id = counter.id
        let descriptor = FetchDescriptor<CustomCounterLog>(predicate: #Predicate { $0.counterID == id })
        if let logs = try? context.fetch(descriptor) {
            for log in logs { context.delete(log) }
        }
        context.delete(counter)
    }
}
