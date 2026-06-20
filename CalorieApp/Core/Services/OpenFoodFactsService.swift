import Foundation

enum FoodLookupError: LocalizedError {
    case notFound
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Продукт не найден в базе Open Food Facts."
        case .network(let m): return "Ошибка сети: \(m)"
        }
    }
}

struct OpenFoodFactsService {

    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg)
    }()

    private let userAgent = "CalorieApp/1.0 (iOS; personal use)"

    func product(barcode: String) async throws -> FoodInfo {
        if let cached = FoodCache.shared.barcode(barcode) { return cached }
        let fields = "code,product_name,product_name_ru,brands,nutriments,serving_quantity,product_quantity,product_quantity_unit,quantity"
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(fields)"
        guard let url = URL(string: urlString) else { throw FoodLookupError.notFound }

        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await session.data(for: req)
            let resp = try JSONDecoder().decode(OFFProductResponse.self, from: data)
            guard resp.status == 1, let p = resp.product else {
                throw FoodLookupError.notFound
            }
            let info = try p.toFoodInfo(barcode: barcode, usePackageQuantity: true)
            FoodCache.shared.storeBarcode(barcode, info: info)
            return info
        } catch let e as FoodLookupError {
            throw e
        } catch {
            throw FoodLookupError.network(error.localizedDescription)
        }
    }

    func search(_ query: String, limit: Int = 25) async throws -> [FoodInfo] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty,
              let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        if let cached = FoodCache.shared.search(q) { return cached }
        let urlString = """
        https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)\
        &search_simple=1&action=process&json=1&page_size=\(limit)\
        &fields=code,product_name,product_name_ru,brands,nutriments
        """
        guard let url = URL(string: urlString) else { return [] }

        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await session.data(for: req)
            let resp = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            let results = (resp.products ?? []).compactMap { try? $0.toFoodInfo(barcode: $0.code, usePackageQuantity: false) }
            FoodCache.shared.storeSearch(q, results: results)
            return results
        } catch {
            throw FoodLookupError.network(error.localizedDescription)
        }
    }
}

private struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]?
}

private struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let productNameRu: String?
    let brands: String?
    let nutriments: OFFNutriments?

    let productQuantity: Double?
    let quantity: String?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case productNameRu = "product_name_ru"
        case brands
        case nutriments
        case productQuantity = "product_quantity"
        case quantity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.decodeIfPresent(String.self, forKey: .code)
        productName = try c.decodeIfPresent(String.self, forKey: .productName)
        productNameRu = try c.decodeIfPresent(String.self, forKey: .productNameRu)
        brands = try c.decodeIfPresent(String.self, forKey: .brands)
        nutriments = try c.decodeIfPresent(OFFNutriments.self, forKey: .nutriments)
        quantity = try? c.decodeIfPresent(String.self, forKey: .quantity)

        if let d = try? c.decode(Double.self, forKey: .productQuantity) {
            productQuantity = d
        } else if let s = try? c.decode(String.self, forKey: .productQuantity) {
            productQuantity = Double(s.replacingOccurrences(of: ",", with: "."))
        } else {
            productQuantity = nil
        }
    }

    func toFoodInfo(barcode: String?, usePackageQuantity: Bool) throws -> FoodInfo {
        let displayName = (productNameRu?.nonEmpty ?? productName?.nonEmpty) ?? "Без названия"
        guard let n = nutriments else { throw FoodLookupError.notFound }

        var grams = 100.0
        if usePackageQuantity {
            let net = productQuantity ?? quantity.flatMap(Self.parseQuantityToGrams)
            if let net, net >= 1, net <= 3000 {
                grams = net.rounded()
            }
        }

        return FoodInfo(
            name: displayName,
            brand: brands?.nonEmpty,
            barcode: barcode,
            kcalPer100: n.kcal100 ?? 0,
            proteinPer100: n.proteins100 ?? 0,
            fatPer100: n.fat100 ?? 0,
            carbsPer100: n.carbs100 ?? 0,
            saturatedFatPer100: n.satFat100,
            defaultGrams: grams
        )
    }

    static func parseQuantityToGrams(_ raw: String) -> Double? {
        let s = raw.lowercased().replacingOccurrences(of: ",", with: ".")
        guard let r = s.range(of: "[0-9]+(\\.[0-9]+)?", options: .regularExpression),
              let value = Double(s[r]) else { return nil }
        let unit = s[r.upperBound...]
        func has(_ u: String) -> Bool { unit.contains(u) }
        if has("kg") || has("кг") { return value * 1000 }
        if has("ml") || has("мл") { return value }
        if has("cl") { return value * 10 }
        if has("l") || has("л") { return value * 1000 }
        if has("oz") { return value * 28.35 }
        return value
    }
}

private struct OFFNutriments: Decodable {
    let kcal100: Double?
    let proteins100: Double?
    let fat100: Double?
    let carbs100: Double?
    let satFat100: Double?

    enum CodingKeys: String, CodingKey {
        case kcal100 = "energy-kcal_100g"
        case proteins100 = "proteins_100g"
        case fat100 = "fat_100g"
        case carbs100 = "carbohydrates_100g"
        case satFat100 = "saturated-fat_100g"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kcal100 = Self.double(c, .kcal100)
        proteins100 = Self.double(c, .proteins100)
        fat100 = Self.double(c, .fat100)
        carbs100 = Self.double(c, .carbs100)
        satFat100 = Self.double(c, .satFat100)
    }

    private static func double(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let s = try? c.decode(String.self, forKey: key) { return Double(s) }
        return nil
    }
}

private extension String {
    var nonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
