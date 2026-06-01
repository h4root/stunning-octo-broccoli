import Foundation

struct FoodService {
    static let shared = FoodService()

    private let off = OpenFoodFactsService()

    func product(barcode: String) async throws -> FoodInfo {
        try await off.product(barcode: barcode)
    }

    func search(_ query: String, limit: Int = 25) async throws -> [FoodInfo] {
        try await off.search(query, limit: limit)
    }
}
