import Foundation

enum CustomCounterStore {
    static func value(_ logs: [CustomCounterLog]) -> Double { logs.first?.value ?? 0 }
    static func progress(value: Double, goal: Double) -> Double { goal > 0 ? min(value / goal, 1) : 0 }
    static func done(value: Double, goal: Double) -> Bool { goal > 0 && value >= goal }

    @discardableResult
    static func add(amount: Double, counterID: UUID, into logs: [CustomCounterLog], day: Date, store: Store) -> Double {
        let newValue = max(0, value(logs) + amount)
        store.setCounter(counterID: counterID, day: day, value: newValue)
        return newValue
    }

    static func delete(_ counter: CustomCounter, store: Store) {
        store.deleteCounter(counter)
    }
}
