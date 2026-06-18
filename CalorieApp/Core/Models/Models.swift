import Foundation

enum Meal: String, CaseIterable, Identifiable, Codable {
    case breakfast, lunch, dinner, snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: return "Завтрак"
        case .lunch:     return "Обед"
        case .dinner:    return "Ужин"
        case .snack:     return "Перекус"
        }
    }

    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.fill"
        case .snack:     return "carrot.fill"
        }
    }
}

struct FoodEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var createdAt = Date()
    var day: Date
    var mealRaw: String
    var name: String
    var brand: String?
    var barcode: String?
    var grams: Double
    var kcalPer100: Double
    var proteinPer100: Double
    var fatPer100: Double
    var carbsPer100: Double
    var note: String = ""
    var isLiquid: Bool = false

    init(name: String,
         brand: String? = nil,
         barcode: String? = nil,
         grams: Double = 100,
         kcalPer100: Double,
         proteinPer100: Double,
         fatPer100: Double,
         carbsPer100: Double,
         meal: Meal,
         day: Date = Date(),
         note: String = "",
         isLiquid: Bool = false) {
        self.day = Calendar.current.startOfDay(for: day)
        self.mealRaw = meal.rawValue
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.grams = grams
        self.kcalPer100 = kcalPer100
        self.proteinPer100 = proteinPer100
        self.fatPer100 = fatPer100
        self.carbsPer100 = carbsPer100
        self.note = note
        self.isLiquid = isLiquid
    }

    var unit: String { isLiquid ? "мл" : "г" }

    var meal: Meal {
        get { Meal(rawValue: mealRaw) ?? .snack }
        set { mealRaw = newValue.rawValue }
    }

    var factor: Double { grams / 100.0 }
    var kcal: Double { kcalPer100 * factor }
    var protein: Double { proteinPer100 * factor }
    var fat: Double { fatPer100 * factor }
    var carbs: Double { carbsPer100 * factor }
}

struct WaterLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var day: Date
    var ml: Double

    init(day: Date, ml: Double) {
        self.day = Calendar.current.startOfDay(for: day)
        self.ml = ml
    }
}

struct BeerLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var createdAt = Date()
    var day: Date
    var brand: String
    var ml: Double = 500
    var abv: Double = 4.5

    init(day: Date, brand: String, ml: Double = 500, abv: Double = 4.5) {
        self.day = Calendar.current.startOfDay(for: day)
        self.brand = brand
        self.ml = ml
        self.abv = abv
    }

    var bottles: Double { ml / 500.0 }
    var alcoholGrams: Double { ml * (abv / 100.0) * 0.789 }
}

struct CustomCounter: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var unit: String = "шт"
    var amounts: [Double] = [1]
    var goal: Double = 0
    var createdAt = Date()
    var sortIndex: Int = 0

    init(name: String, unit: String, amounts: [Double], goal: Double = 0, sortIndex: Int = 0) {
        self.name = name
        self.unit = unit
        self.amounts = amounts
        self.goal = goal
        self.sortIndex = sortIndex
    }
}

struct CustomCounterLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var counterID: UUID
    var day: Date
    var value: Double

    init(counterID: UUID, day: Date, value: Double) {
        self.counterID = counterID
        self.day = Calendar.current.startOfDay(for: day)
        self.value = value
    }
}

struct SavedFood: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var brand: String?
    var barcode: String?
    var kcalPer100: Double
    var proteinPer100: Double
    var fatPer100: Double
    var carbsPer100: Double
    var defaultGrams: Double = 100
    var lastUsed = Date()
    var useCount: Int = 0
    var isFavorite: Bool = false
    var isLiquid: Bool = false

    init(name: String,
         brand: String? = nil,
         barcode: String? = nil,
         kcalPer100: Double,
         proteinPer100: Double,
         fatPer100: Double,
         carbsPer100: Double,
         defaultGrams: Double = 100,
         isLiquid: Bool = false) {
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.kcalPer100 = kcalPer100
        self.proteinPer100 = proteinPer100
        self.fatPer100 = fatPer100
        self.carbsPer100 = carbsPer100
        self.defaultGrams = defaultGrams
        self.isLiquid = isLiquid
    }
}

struct FoodInfo: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var brand: String?
    var barcode: String?
    var kcalPer100: Double
    var proteinPer100: Double
    var fatPer100: Double
    var carbsPer100: Double
    var defaultGrams: Double = 100
    var isLiquid: Bool = false

    init(name: String,
         brand: String? = nil,
         barcode: String? = nil,
         kcalPer100: Double,
         proteinPer100: Double,
         fatPer100: Double,
         carbsPer100: Double,
         defaultGrams: Double = 100,
         isLiquid: Bool = false) {
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.kcalPer100 = kcalPer100
        self.proteinPer100 = proteinPer100
        self.fatPer100 = fatPer100
        self.carbsPer100 = carbsPer100
        self.defaultGrams = defaultGrams
        self.isLiquid = isLiquid
    }

    init(saved: SavedFood) {
        self.name = saved.name
        self.brand = saved.brand
        self.barcode = saved.barcode
        self.kcalPer100 = saved.kcalPer100
        self.proteinPer100 = saved.proteinPer100
        self.fatPer100 = saved.fatPer100
        self.carbsPer100 = saved.carbsPer100
        self.defaultGrams = saved.defaultGrams
        self.isLiquid = saved.isLiquid
    }
}
