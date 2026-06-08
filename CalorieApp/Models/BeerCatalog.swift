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
    static let heineken: [Beer] = [
        Beer(name: "Heineken", owner: "Heineken", abv: 5.0, kcalPer100: 42, colorHex: 0x2E7D32),
        Beer(name: "Amstel Premium", owner: "Heineken", abv: 4.8, kcalPer100: 43, colorHex: 0xC62828),
        Beer(name: "Krušovice", owner: "Heineken", abv: 4.2, kcalPer100: 41, colorHex: 0xB71C1C),
        Beer(name: "Gösser", owner: "Heineken", abv: 4.7, kcalPer100: 42, colorHex: 0x2E5D34),
        Beer(name: "Edelweiss", owner: "Heineken", abv: 5.3, kcalPer100: 49, colorHex: 0xE9B949),
        Beer(name: "Affligem", owner: "Heineken", abv: 6.7, kcalPer100: 55, colorHex: 0x8D6E63),
        Beer(name: "Бочкарёв", owner: "Heineken", abv: 4.7, kcalPer100: 43, colorHex: 0xF9A825),
        Beer(name: "Охота крепкое", owner: "Heineken", abv: 8.1, kcalPer100: 58, colorHex: 0xC0392B),
        Beer(name: "Три медведя", owner: "Heineken", abv: 4.5, kcalPer100: 42, colorHex: 0x6D4C41),
        Beer(name: "ПИТ", owner: "Heineken", abv: 4.6, kcalPer100: 42, colorHex: 0xEF6C00),
        Beer(name: "Доктор Дизель", owner: "Heineken", abv: 5.2, kcalPer100: 45, colorHex: 0x37474F),
        Beer(name: "Zlatý Bažant", owner: "Heineken", abv: 5.0, kcalPer100: 43, colorHex: 0xD4AF37)
    ]

    static let others: [Beer] = [
        Beer(name: "Балтика 7", owner: "Carlsberg", abv: 5.4, kcalPer100: 46, colorHex: 0x0D47A1),
        Beer(name: "Балтика 9", owner: "Carlsberg", abv: 8.0, kcalPer100: 58, colorHex: 0xB71C1C),
        Beer(name: "Жигули Барное", owner: "Москва-Эфес", abv: 4.9, kcalPer100: 42, colorHex: 0xEF9A00),
        Beer(name: "Старый Мельник", owner: "Эфес", abv: 4.7, kcalPer100: 43, colorHex: 0x8E6E3C),
        Beer(name: "Tuborg Green", owner: "Carlsberg", abv: 4.6, kcalPer100: 42, colorHex: 0x2E7D32),
        Beer(name: "Carlsberg", owner: "Carlsberg", abv: 5.0, kcalPer100: 43, colorHex: 0x1B5E20),
        Beer(name: "Velkopopovický Kozel", owner: "Эфес", abv: 4.6, kcalPer100: 42, colorHex: 0xC8A415),
        Beer(name: "Stella Artois", owner: "AB InBev", abv: 5.0, kcalPer100: 43, colorHex: 0xC62828),
        Beer(name: "Сибирская корона", owner: "AB InBev", abv: 5.3, kcalPer100: 45, colorHex: 0xB8860B),
        Beer(name: "Клинское", owner: "AB InBev", abv: 4.5, kcalPer100: 42, colorHex: 0x1565C0),
        Beer(name: "Guinness", owner: "Diageo", abv: 4.2, kcalPer100: 35, colorHex: 0x212121),
        Beer(name: "Corona Extra", owner: "AB InBev", abv: 4.5, kcalPer100: 42, colorHex: 0xFBC02D)
    ]

    static let all: [Beer] = heineken + others

    static func find(_ name: String) -> Beer? { all.first { $0.name == name } }
}
