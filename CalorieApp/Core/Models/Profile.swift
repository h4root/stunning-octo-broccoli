import Foundation

enum Sex: String, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var title: String { self == .male ? "Мужской" : "Женский" }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary, light, moderate, high, veryHigh
    var id: String { rawValue }

    var factor: Double {
        switch self {
        case .sedentary: return 1.2
        case .light:     return 1.375
        case .moderate:  return 1.55
        case .high:      return 1.725
        case .veryHigh:  return 1.9
        }
    }

    var title: String {
        switch self {
        case .sedentary: return "Сидячий"
        case .light:     return "Лёгкая"
        case .moderate:  return "Умеренная"
        case .high:      return "Высокая"
        case .veryHigh:  return "Очень высокая"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: return "Мало движения, сидячая работа"
        case .light:     return "Тренировки 1–3 раза в неделю"
        case .moderate:  return "Тренировки 3–5 раз в неделю"
        case .high:      return "Тренировки 6–7 раз в неделю"
        case .veryHigh:  return "Тяжёлый физический труд или тренировки дважды в день"
        }
    }
}

enum GoalType: String, CaseIterable, Identifiable {
    case lose, maintain, gain
    var id: String { rawValue }

    var title: String {
        switch self {
        case .lose:     return "Похудение"
        case .maintain: return "Поддержание"
        case .gain:     return "Набор массы"
        }
    }

    var kcalDelta: Double {
        switch self {
        case .lose:     return -400
        case .maintain: return 0
        case .gain:     return 350
        }
    }

    var proteinPerKg: Double {
        switch self {
        case .lose:     return 2.0
        case .maintain: return 1.8
        case .gain:     return 2.0
        }
    }
}

enum GoalCalculator {

    static func bmr(sex: Sex, age: Int, heightCm: Double, weightKg: Double) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return base + (sex == .male ? 5 : -161)
    }

    static func goals(sex: Sex, age: Int, heightCm: Double, weightKg: Double,
                      activity: ActivityLevel, goal: GoalType) -> DailyGoals {
        let tdee = bmr(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg) * activity.factor
        let kcal = max(tdee + goal.kcalDelta, 1000)

        let protein = weightKg * goal.proteinPerKg
        let fat = (kcal * 0.27) / 9
        let proteinKcal = protein * 4
        let fatKcal = fat * 9
        let carbs = max((kcal - proteinKcal - fatKcal) / 4, 0)

        return DailyGoals(
            kcal: (kcal / 10).rounded() * 10,
            protein: protein.rounded(),
            fat: fat.rounded(),
            carbs: carbs.rounded()
        )
    }
}
