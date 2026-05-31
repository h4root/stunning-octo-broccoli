import Foundation

final class FoodCache {
    static let shared = FoodCache()
    private init() { loadBarcodes() }

    private let barcodeTTL: TimeInterval = 14 * 24 * 3600
    private let searchTTL: TimeInterval = 10 * 60
    private let defaultsKey = "foodCache.barcodes"

    private struct Entry: Codable {
        let date: Date
        let info: FoodInfo
    }

    private var barcodes: [String: Entry] = [:]
    private var searches: [String: (date: Date, results: [FoodInfo])] = [:]

    func barcode(_ code: String) -> FoodInfo? {
        guard let e = barcodes[code], Date().timeIntervalSince(e.date) < barcodeTTL else { return nil }
        return e.info
    }

    func storeBarcode(_ code: String, info: FoodInfo) {
        barcodes[code] = Entry(date: Date(), info: info)
        saveBarcodes()
    }

    func search(_ query: String) -> [FoodInfo]? {
        let key = query.lowercased()
        guard let e = searches[key], Date().timeIntervalSince(e.date) < searchTTL else { return nil }
        return e.results
    }

    func storeSearch(_ query: String, results: [FoodInfo]) {
        searches[query.lowercased()] = (Date(), results)
    }

    private func saveBarcodes() {

        if barcodes.count > 500 {
            let sorted = barcodes.sorted { $0.value.date > $1.value.date }
            barcodes = Dictionary(uniqueKeysWithValues: sorted.prefix(500).map { ($0.key, $0.value) })
        }
        if let data = try? JSONEncoder().encode(barcodes) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func loadBarcodes() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) else { return }
        barcodes = decoded
    }
}
