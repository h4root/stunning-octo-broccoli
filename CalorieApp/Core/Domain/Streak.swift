import Foundation

func computeStreak(days: Set<Date>) -> Int {
    let cal = Calendar.current
    var d = cal.startOfDay(for: Date())
    if !days.contains(d) {
        guard let y = cal.date(byAdding: .day, value: -1, to: d), days.contains(y) else { return 0 }
        d = y
    }
    var streak = 0
    while days.contains(d) {
        streak += 1
        guard let p = cal.date(byAdding: .day, value: -1, to: d) else { break }
        d = p
    }
    return streak
}

enum CalorieStreak {
    static func completed(perDay: [Date: Double], goalKcal: Double, today: Date = Date()) -> Int {
        guard goalKcal > 0 else { return 0 }
        let cal = Calendar.current
        func met(_ d: Date) -> Bool { (perDay[cal.startOfDay(for: d)] ?? 0) >= goalKcal }

        var d = cal.startOfDay(for: today)
        if !met(d) {
            guard let y = cal.date(byAdding: .day, value: -1, to: d), met(y) else { return 0 }
            d = y
        }
        var streak = 0
        while met(d) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return streak
    }
}
