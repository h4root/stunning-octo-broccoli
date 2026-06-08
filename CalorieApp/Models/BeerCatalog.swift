import SwiftUI

struct Beer: Identifiable, Hashable {
    let name: String
    let owner: String
    let abv: Double
    let kcalPer100: Double
    let colorHex: UInt
    var id: String { name }

    var color: Color { Color(hex: colorHex) }
    var kcalPerBottle: Double { kcalPer100 * 5 }
}

enum BeerCatalog {
    static let bochkarev: [Beer] = [
        Beer(name: "Бочкарёв", owner: "Бочкарёв", abv: 4.7, kcalPer100: 43, colorHex: 0xF9A825),
        Beer(name: "La Costa Fresca", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0x8DC63F),
        Beer(name: "Dr. Diesel", owner: "Бочкарёв", abv: 6.9, kcalPer100: 56, colorHex: 0x37474F),
        Beer(name: "Мистер Лис", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0xE07B39),
        Beer(name: "Gold Beer", owner: "Бочкарёв", abv: 4.6, kcalPer100: 43, colorHex: 0xD4AF37),
        Beer(name: "Жигулёвское 1978", owner: "Бочкарёв", abv: 4.0, kcalPer100: 41, colorHex: 0xEF9A00),
        Beer(name: "Black Sheep", owner: "Бочкарёв", abv: 4.8, kcalPer100: 44, colorHex: 0x263238),
        Beer(name: "Edelweiss", owner: "Бочкарёв", abv: 5.3, kcalPer100: 49, colorHex: 0xE9B949),
        Beer(name: "Берег Байкала", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0x2E86C1),
        Beer(name: "Okome", owner: "Бочкарёв", abv: 5.0, kcalPer100: 44, colorHex: 0xC0A062),
        Beer(name: "Три Медведя", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0x6D4C41),
        Beer(name: "ПИТ", owner: "Бочкарёв", abv: 4.6, kcalPer100: 42, colorHex: 0xEF6C00),
        Beer(name: "Степан Разин", owner: "Бочкарёв", abv: 4.8, kcalPer100: 43, colorHex: 0xB03A2E),
        Beer(name: "Feilong", owner: "Бочкарёв", abv: 4.7, kcalPer100: 43, colorHex: 0xC0392B),
        Beer(name: "Окское", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0x1E8449),
        Beer(name: "Gösser", owner: "Бочкарёв", abv: 4.7, kcalPer100: 42, colorHex: 0x2E5D34),
        Beer(name: "Шихан", owner: "Бочкарёв", abv: 4.8, kcalPer100: 43, colorHex: 0xB8860B),
        Beer(name: "Охота Крепкое", owner: "Бочкарёв", abv: 8.1, kcalPer100: 58, colorHex: 0x8B0000),
        Beer(name: "Maison Arne", owner: "Бочкарёв", abv: 5.0, kcalPer100: 44, colorHex: 0x6C3483),
        Beer(name: "Krušovice Kronprinz", owner: "Бочкарёв", abv: 5.0, kcalPer100: 43, colorHex: 0xB71C1C),
        Beer(name: "Калинкинъ", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0xCB4335),
        Beer(name: "United Legacy", owner: "Бочкарёв", abv: 5.0, kcalPer100: 45, colorHex: 0x34495E),
        Beer(name: "Белый Кремль", owner: "Бочкарёв", abv: 4.8, kcalPer100: 46, colorHex: 0xAEB6BF),
        Beer(name: "Москвич", owner: "Бочкарёв", abv: 4.5, kcalPer100: 42, colorHex: 0x922B21)
    ]

    static let baltika: [Beer] = [
        Beer(name: "Балтика 7", owner: "Балтика", abv: 5.4, kcalPer100: 46, colorHex: 0x0D47A1),
        Beer(name: "Балтика 9", owner: "Балтика", abv: 8.0, kcalPer100: 58, colorHex: 0xB71C1C),
        Beer(name: "Арсенальное", owner: "Балтика", abv: 5.1, kcalPer100: 45, colorHex: 0x4E342E),
        Beer(name: "Бархатное", owner: "Балтика", abv: 4.8, kcalPer100: 48, colorHex: 0x3E2723),
        Beer(name: "Большая Кружка", owner: "Балтика", abv: 4.6, kcalPer100: 44, colorHex: 0xF57F17),
        Beer(name: "Варварка-Пивоварка", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0xAD1457),
        Beer(name: "Горьковское", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x6D4C41),
        Beer(name: "Дикий Восток", owner: "Балтика", abv: 4.7, kcalPer100: 44, colorHex: 0x33691E),
        Beer(name: "Дон", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x00695C),
        Beer(name: "Дракон", owner: "Балтика", abv: 4.8, kcalPer100: 44, colorHex: 0xC62828),
        Beer(name: "Жигулёвское", owner: "Балтика", abv: 4.0, kcalPer100: 41, colorHex: 0xEF9A00),
        Beer(name: "Заповедное", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x2E7D32),
        Beer(name: "Морсберри", owner: "Балтика", abv: 4.5, kcalPer100: 45, colorHex: 0xC2185B),
        Beer(name: "Московское Классическое", owner: "Балтика", abv: 4.8, kcalPer100: 44, colorHex: 0x5D4037),
        Beer(name: "Невское", owner: "Балтика", abv: 4.8, kcalPer100: 44, colorHex: 0x1565C0),
        Beer(name: "Рижское", owner: "Балтика", abv: 4.7, kcalPer100: 43, colorHex: 0x00838F),
        Beer(name: "Русский Имперский Стаут", owner: "Балтика", abv: 8.5, kcalPer100: 70, colorHex: 0x1B0E08),
        Beer(name: "Самара", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x0277BD),
        Beer(name: "Сибирский Бочонок", owner: "Балтика", abv: 4.7, kcalPer100: 44, colorHex: 0x4E342E),
        Beer(name: "Хрустальная", owner: "Балтика", abv: 4.5, kcalPer100: 42, colorHex: 0x64B5F6),
        Beer(name: "Чаваш Хамли", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x8D6E63),
        Beer(name: "Челябинское", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x455A64),
        Beer(name: "Чешский Медведь", owner: "Балтика", abv: 4.8, kcalPer100: 44, colorHex: 0xB8860B),
        Beer(name: "Ярпиво", owner: "Балтика", abv: 4.7, kcalPer100: 44, colorHex: 0xF9A825),
        Beer(name: "Flash UP", owner: "Балтика", abv: 6.5, kcalPer100: 52, colorHex: 0x00BCD4),
        Beer(name: "GreenBeat", owner: "Балтика", abv: 6.0, kcalPer100: 50, colorHex: 0x76FF03),
        Beer(name: "Krone Blanche", owner: "Балтика", abv: 4.8, kcalPer100: 45, colorHex: 0xEAD9A0),
        Beer(name: "Old Bobby", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0x795548),
        Beer(name: "Rodnoe", owner: "Балтика", abv: 4.5, kcalPer100: 43, colorHex: 0xEF6C00),
        Beer(name: "Tony's Garret", owner: "Балтика", abv: 4.7, kcalPer100: 44, colorHex: 0x37474F),
        Beer(name: "Zatecky Gus", owner: "Балтика", abv: 4.6, kcalPer100: 43, colorHex: 0xC8A415)
    ]

    static let wheat: [Beer] = [
        Beer(name: "Hoegaarden", owner: "Бельгия · витбир", abv: 4.9, kcalPer100: 43, colorHex: 0xE8D8A0),
        Beer(name: "Blanche de Bruxelles", owner: "Бельгия · витбир", abv: 4.5, kcalPer100: 43, colorHex: 0xEAD9B0),
        Beer(name: "St. Bernardus Wit", owner: "Бельгия · витбир", abv: 5.5, kcalPer100: 47, colorHex: 0xE6D7A8),
        Beer(name: "Celis White", owner: "Бельгия · витбир", abv: 5.0, kcalPer100: 45, colorHex: 0xEADCB2),
        Beer(name: "Leffe Blonde", owner: "Бельгия · аббатское", abv: 6.6, kcalPer100: 52, colorHex: 0xE3B23C),
        Beer(name: "Paulaner Hefe-Weißbier", owner: "Германия · вайцен", abv: 5.5, kcalPer100: 48, colorHex: 0xD9A441),
        Beer(name: "Erdinger Weißbier", owner: "Германия · вайцен", abv: 5.3, kcalPer100: 47, colorHex: 0xC8941F),
        Beer(name: "Franziskaner Weissbier", owner: "Германия · вайцен", abv: 5.0, kcalPer100: 46, colorHex: 0xCBA135),
        Beer(name: "Weihenstephaner Hefe", owner: "Германия · вайцен", abv: 5.4, kcalPer100: 48, colorHex: 0xD4AF37),
        Beer(name: "Schöfferhofer Hefeweizen", owner: "Германия · вайцен", abv: 5.0, kcalPer100: 46, colorHex: 0xE0B84C)
    ]

    static let others: [Beer] = [
        Beer(name: "Жигули Барное", owner: "Эфес", abv: 4.9, kcalPer100: 42, colorHex: 0xEFB000),
        Beer(name: "Старый Мельник", owner: "Эфес", abv: 4.7, kcalPer100: 43, colorHex: 0x8E6E3C),
        Beer(name: "Velkopopovický Kozel", owner: "Эфес", abv: 4.6, kcalPer100: 42, colorHex: 0xC8A415),
        Beer(name: "Stella Artois", owner: "AB InBev", abv: 5.0, kcalPer100: 43, colorHex: 0xC62828),
        Beer(name: "Сибирская корона", owner: "AB InBev", abv: 5.3, kcalPer100: 45, colorHex: 0xB8860B),
        Beer(name: "Клинское", owner: "AB InBev", abv: 4.5, kcalPer100: 42, colorHex: 0x1565C0),
        Beer(name: "Guinness", owner: "Diageo", abv: 4.2, kcalPer100: 35, colorHex: 0x212121),
        Beer(name: "Corona Extra", owner: "AB InBev", abv: 4.5, kcalPer100: 42, colorHex: 0xFBC02D)
    ]

    static let all: [Beer] = bochkarev + baltika + wheat + others

    static func find(_ name: String) -> Beer? { all.first { $0.name == name } }
}
