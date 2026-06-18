import Foundation
import Combine

final class Store: ObservableObject {
    @Published private(set) var foodEntries: [FoodEntry] = []
    @Published private(set) var waterLogs: [WaterLog] = []
    @Published private(set) var beerLogs: [BeerLog] = []
    @Published private(set) var savedFoods: [SavedFood] = []
    @Published private(set) var customCounters: [CustomCounter] = []
    @Published private(set) var customCounterLogs: [CustomCounterLog] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("calorieapp.json")
    }()

    init() { load() }

    private struct Snapshot: Codable {
        var foodEntries: [FoodEntry] = []
        var waterLogs: [WaterLog] = []
        var beerLogs: [BeerLog] = []
        var savedFoods: [SavedFood] = []
        var customCounters: [CustomCounter] = []
        var customCounterLogs: [CustomCounterLog] = []
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        foodEntries = s.foodEntries
        waterLogs = s.waterLogs
        beerLogs = s.beerLogs
        savedFoods = s.savedFoods
        customCounters = s.customCounters
        customCounterLogs = s.customCounterLogs
    }

    private func persist() {
        let s = Snapshot(foodEntries: foodEntries, waterLogs: waterLogs, beerLogs: beerLogs,
                         savedFoods: savedFoods, customCounters: customCounters, customCounterLogs: customCounterLogs)
        if let data = try? JSONEncoder().encode(s) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Food

    func addFood(_ entry: FoodEntry) { foodEntries.append(entry); persist() }

    func deleteFood(_ entry: FoodEntry) { foodEntries.removeAll { $0.id == entry.id }; persist() }

    func updateFood(_ entry: FoodEntry) {
        if let i = foodEntries.firstIndex(where: { $0.id == entry.id }) {
            foodEntries[i] = entry
            persist()
        }
    }

    func upsertSaved(_ info: FoodInfo, grams: Double) {
        let match = savedFoods.firstIndex { food in
            (info.barcode != nil && food.barcode == info.barcode) ||
            (food.barcode == nil && food.name == info.name)
        }
        if let i = match {
            savedFoods[i].lastUsed = Date()
            savedFoods[i].useCount += 1
            savedFoods[i].defaultGrams = grams
            savedFoods[i].kcalPer100 = info.kcalPer100
            savedFoods[i].proteinPer100 = info.proteinPer100
            savedFoods[i].fatPer100 = info.fatPer100
            savedFoods[i].carbsPer100 = info.carbsPer100
            savedFoods[i].isLiquid = info.isLiquid
        } else {
            var saved = SavedFood(name: info.name, brand: info.brand, barcode: info.barcode,
                                  kcalPer100: info.kcalPer100, proteinPer100: info.proteinPer100,
                                  fatPer100: info.fatPer100, carbsPer100: info.carbsPer100,
                                  defaultGrams: grams, isLiquid: info.isLiquid)
            saved.useCount = 1
            savedFoods.append(saved)
        }
        persist()
    }

    func toggleFavorite(_ saved: SavedFood) {
        if let i = savedFoods.firstIndex(where: { $0.id == saved.id }) {
            savedFoods[i].isFavorite.toggle()
            persist()
        }
    }

    // MARK: - Water

    func setWater(day: Date, ml: Double) {
        let start = Calendar.current.startOfDay(for: day)
        if let i = waterLogs.firstIndex(where: { $0.day == start }) {
            if ml <= 0 { waterLogs.remove(at: i) } else { waterLogs[i].ml = ml }
        } else if ml > 0 {
            waterLogs.append(WaterLog(day: start, ml: ml))
        }
        persist()
    }

    // MARK: - Beer

    func addBeer(_ log: BeerLog) { beerLogs.append(log); persist() }

    @discardableResult
    func removeLatestBeer(brand: String, day: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: day)
        if let i = beerLogs.filter({ $0.day == start && $0.brand == brand })
            .sorted(by: { $0.createdAt > $1.createdAt }).first
            .flatMap({ target in beerLogs.firstIndex(where: { $0.id == target.id }) }) {
            beerLogs.remove(at: i)
            persist()
            return true
        }
        return false
    }

    // MARK: - Custom counters

    func addCounter(_ counter: CustomCounter) { customCounters.append(counter); persist() }

    func updateCounter(_ counter: CustomCounter) {
        if let i = customCounters.firstIndex(where: { $0.id == counter.id }) {
            customCounters[i] = counter
            persist()
        }
    }

    func deleteCounter(_ counter: CustomCounter) {
        customCounters.removeAll { $0.id == counter.id }
        customCounterLogs.removeAll { $0.counterID == counter.id }
        persist()
    }

    func setCounter(counterID: UUID, day: Date, value: Double) {
        let start = Calendar.current.startOfDay(for: day)
        if let i = customCounterLogs.firstIndex(where: { $0.counterID == counterID && $0.day == start }) {
            customCounterLogs[i].value = value
        } else if value > 0 {
            customCounterLogs.append(CustomCounterLog(counterID: counterID, day: start, value: value))
        }
        persist()
    }
}
