import Foundation

struct ClassicFood: Identifiable {
    let id = UUID()
    let name: String
    let nameEn: String
    let kcal: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let saturated: Double?
    let isLiquid: Bool

    init(_ name: String, _ nameEn: String, _ kcal: Double, _ protein: Double, _ fat: Double, _ carbs: Double, saturated: Double? = nil, liquid: Bool = false) {
        self.name = name
        self.nameEn = nameEn
        self.kcal = kcal
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.saturated = saturated
        self.isLiquid = liquid
    }

    func toFoodInfo() -> FoodInfo {
        FoodInfo(name: name, brand: nil, barcode: nil,
                 kcalPer100: kcal, proteinPer100: protein, fatPer100: fat, carbsPer100: carbs,
                 saturatedFatPer100: saturated,
                 defaultGrams: isLiquid ? 250 : 100, isLiquid: isLiquid)
    }
}

enum ClassicFoodsDB {
    static func search(_ query: String, limit: Int = 12) -> [ClassicFood] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard q.count >= 1 else { return [] }
        let matches = all.filter {
            $0.name.lowercased().contains(q) || $0.nameEn.lowercased().contains(q)
        }
        // Сначала те, что начинаются с запроса
        let sorted = matches.sorted { a, b in
            let aStarts = a.name.lowercased().hasPrefix(q) || a.nameEn.lowercased().hasPrefix(q)
            let bStarts = b.name.lowercased().hasPrefix(q) || b.nameEn.lowercased().hasPrefix(q)
            if aStarts != bStarts { return aStarts }
            return a.name < b.name
        }
        return Array(sorted.prefix(limit))
    }

    // КБЖУ на 100 г. Значения — общеизвестные усреднённые.
    static let all: [ClassicFood] = [
        // Фрукты
        ClassicFood("Банан", "Banana", 89, 1.1, 0.3, 23),
        ClassicFood("Яблоко", "Apple", 52, 0.3, 0.2, 14),
        ClassicFood("Апельсин", "Orange", 47, 0.9, 0.1, 12),
        ClassicFood("Груша", "Pear", 57, 0.4, 0.1, 15),
        ClassicFood("Виноград", "Grapes", 69, 0.7, 0.2, 18),
        ClassicFood("Клубника", "Strawberry", 32, 0.7, 0.3, 8),
        ClassicFood("Мандарин", "Tangerine", 53, 0.8, 0.3, 13),
        ClassicFood("Киви", "Kiwi", 61, 1.1, 0.5, 15),
        ClassicFood("Манго", "Mango", 60, 0.8, 0.4, 15),
        ClassicFood("Ананас", "Pineapple", 50, 0.5, 0.1, 13),
        ClassicFood("Арбуз", "Watermelon", 30, 0.6, 0.2, 8),
        ClassicFood("Авокадо", "Avocado", 160, 2, 15, 9, saturated: 2.1),
        ClassicFood("Лимон", "Lemon", 29, 1.1, 0.3, 9),
        ClassicFood("Персик", "Peach", 39, 0.9, 0.3, 10),
        ClassicFood("Черника", "Blueberry", 57, 0.7, 0.3, 14),

        // Овощи
        ClassicFood("Картофель варёный", "Boiled potato", 87, 1.9, 0.1, 20),
        ClassicFood("Морковь", "Carrot", 41, 0.9, 0.2, 10),
        ClassicFood("Огурец", "Cucumber", 15, 0.7, 0.1, 3.6),
        ClassicFood("Помидор", "Tomato", 18, 0.9, 0.2, 3.9),
        ClassicFood("Брокколи", "Broccoli", 34, 2.8, 0.4, 7),
        ClassicFood("Капуста", "Cabbage", 25, 1.3, 0.1, 6),
        ClassicFood("Лук репчатый", "Onion", 40, 1.1, 0.1, 9),
        ClassicFood("Перец болгарский", "Bell pepper", 26, 1, 0.3, 6),
        ClassicFood("Свёкла", "Beetroot", 43, 1.6, 0.2, 10),
        ClassicFood("Кукуруза", "Corn", 86, 3.2, 1.2, 19),
        ClassicFood("Шпинат", "Spinach", 23, 2.9, 0.4, 3.6),
        ClassicFood("Шампиньоны", "Mushrooms", 22, 3.1, 0.3, 3.3),
        ClassicFood("Цветная капуста", "Cauliflower", 25, 1.9, 0.3, 5),

        // Крупы, гарниры, хлеб
        ClassicFood("Рис варёный", "Boiled rice", 130, 2.7, 0.3, 28),
        ClassicFood("Гречка варёная", "Boiled buckwheat", 110, 4, 1.1, 21),
        ClassicFood("Овсяная каша на воде", "Oatmeal", 88, 3, 1.7, 15),
        ClassicFood("Макароны варёные", "Boiled pasta", 131, 5, 1.1, 25),
        ClassicFood("Хлеб белый", "White bread", 265, 9, 3.2, 49),
        ClassicFood("Хлеб ржаной", "Rye bread", 250, 8.5, 3.3, 48),
        ClassicFood("Гречка сухая", "Buckwheat dry", 343, 13, 3.4, 72),
        ClassicFood("Рис сухой", "Rice dry", 360, 7, 1, 78),
        ClassicFood("Овсяные хлопья сухие", "Rolled oats", 379, 13, 6.5, 67),
        ClassicFood("Картофель фри", "French fries", 312, 3.4, 15, 41, saturated: 2.3),

        // Мясо, птица, рыба
        ClassicFood("Куриная грудка", "Chicken breast", 165, 31, 3.6, 0, saturated: 1.0),
        ClassicFood("Куриное бедро", "Chicken thigh", 209, 26, 11, 0, saturated: 3.0),
        ClassicFood("Говядина", "Beef", 250, 26, 15, 0, saturated: 6),
        ClassicFood("Свинина", "Pork", 242, 27, 14, 0, saturated: 5),
        ClassicFood("Индейка", "Turkey", 189, 29, 7, 0, saturated: 2),
        ClassicFood("Фарш говяжий", "Ground beef", 254, 26, 16, 0, saturated: 6.6),
        ClassicFood("Лосось", "Salmon", 208, 20, 13, 0, saturated: 3.1),
        ClassicFood("Тунец консервированный", "Canned tuna", 116, 26, 1, 0),
        ClassicFood("Креветки", "Shrimp", 99, 24, 0.3, 0.2),
        ClassicFood("Треска", "Cod", 82, 18, 0.7, 0),
        ClassicFood("Сосиски", "Sausages", 280, 12, 25, 2, saturated: 9),
        ClassicFood("Бекон", "Bacon", 541, 37, 42, 1.4, saturated: 14),

        // Молочка, яйца
        ClassicFood("Яйцо куриное", "Egg", 155, 13, 11, 1.1, saturated: 3.3),
        ClassicFood("Молоко 2.5%", "Milk", 52, 2.9, 2.5, 4.8, saturated: 1.5, liquid: true),
        ClassicFood("Творог 5%", "Cottage cheese 5%", 121, 17, 5, 3, saturated: 3),
        ClassicFood("Творог 9%", "Cottage cheese 9%", 159, 16, 9, 2, saturated: 5.5),
        ClassicFood("Сыр", "Cheese", 364, 25, 29, 1.3, saturated: 18),
        ClassicFood("Йогурт натуральный", "Plain yogurt", 60, 5, 3.2, 4.7, saturated: 2),
        ClassicFood("Йогурт греческий", "Greek yogurt", 59, 10, 0.4, 3.6, saturated: 0.1),
        ClassicFood("Сметана 20%", "Sour cream", 206, 2.8, 20, 3.2, saturated: 12),
        ClassicFood("Масло сливочное", "Butter", 717, 0.9, 81, 0.1, saturated: 51),
        ClassicFood("Кефир 1%", "Kefir", 40, 3, 1, 4, saturated: 0.7, liquid: true),

        // Орехи, бобовые
        ClassicFood("Миндаль", "Almonds", 579, 21, 50, 22, saturated: 3.8),
        ClassicFood("Грецкий орех", "Walnuts", 654, 15, 65, 14, saturated: 6.1),
        ClassicFood("Арахис", "Peanuts", 567, 26, 49, 16, saturated: 6.8),
        ClassicFood("Арахисовая паста", "Peanut butter", 588, 25, 50, 20, saturated: 10),
        ClassicFood("Фасоль варёная", "Boiled beans", 127, 9, 0.5, 23),
        ClassicFood("Чечевица варёная", "Boiled lentils", 116, 9, 0.4, 20),
        ClassicFood("Нут варёный", "Chickpeas", 164, 9, 2.6, 27),

        // Жиры, сладкое, прочее
        ClassicFood("Оливковое масло", "Olive oil", 884, 0, 100, 0, saturated: 14, liquid: true),
        ClassicFood("Подсолнечное масло", "Sunflower oil", 884, 0, 100, 0, saturated: 11, liquid: true),
        ClassicFood("Мёд", "Honey", 304, 0.3, 0, 82),
        ClassicFood("Сахар", "Sugar", 387, 0, 0, 100),
        ClassicFood("Шоколад тёмный", "Dark chocolate", 546, 4.9, 31, 61, saturated: 19),
        ClassicFood("Шоколад молочный", "Milk chocolate", 535, 7.6, 30, 59, saturated: 18),

        // Напитки
        ClassicFood("Кола", "Cola", 42, 0, 0, 10.6, liquid: true),
        ClassicFood("Сок апельсиновый", "Orange juice", 45, 0.7, 0.2, 10, liquid: true),
        ClassicFood("Пиво", "Beer", 43, 0.5, 0, 3.6, liquid: true),
        ClassicFood("Кофе чёрный", "Black coffee", 1, 0.1, 0, 0, liquid: true),
        ClassicFood("Вода", "Water", 0, 0, 0, 0, liquid: true),
    ]
}
