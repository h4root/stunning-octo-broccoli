import Foundation

struct DailyGoals {
    var kcal: Double
    var protein: Double
    var fat: Double
    var carbs: Double
}

enum GoalsDefaults {
    static let kcal: Double = 2000
    static let protein: Double = 120
    static let fat: Double = 65
    static let carbs: Double = 250
}

struct DayTotals {
    var kcal: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    init() {}

    init(entries: [FoodEntry]) {
        for e in entries {
            kcal += e.kcal
            protein += e.protein
            fat += e.fat
            carbs += e.carbs
        }
    }
}
