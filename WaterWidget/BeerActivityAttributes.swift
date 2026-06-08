import ActivityKit
import AppIntents
import Foundation

struct BeerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var count: Int
        var lastBrand: String
        var colorHex: UInt
    }
}

enum BeerLiveStore {
    static let d = UserDefaults.standard
    static let countKey = "beer.live.count"
    static let brandKey = "beer.live.lastBrand"
    static let colorKey = "beer.live.lastColor"
    static let pendingKey = "beer.live.pending"

    static var count: Int {
        get { d.integer(forKey: countKey) }
        set { d.set(newValue, forKey: countKey) }
    }
    static var lastBrand: String {
        get { d.string(forKey: brandKey) ?? "" }
        set { d.set(newValue, forKey: brandKey) }
    }
    static var lastColor: UInt {
        get { UInt(bitPattern: d.integer(forKey: colorKey)) }
        set { d.set(Int(bitPattern: newValue), forKey: colorKey) }
    }
    static var pending: [String] {
        get { d.stringArray(forKey: pendingKey) ?? [] }
        set { d.set(newValue, forKey: pendingKey) }
    }
}

enum BeerLiveBridge {
    @MainActor
    static func quickAddLast() async {
        guard !BeerLiveStore.lastBrand.isEmpty else { return }
        BeerLiveStore.count += 1
        BeerLiveStore.pending = BeerLiveStore.pending + [BeerLiveStore.lastBrand]
        let state = BeerActivityAttributes.ContentState(
            count: BeerLiveStore.count,
            lastBrand: BeerLiveStore.lastBrand,
            colorHex: BeerLiveStore.lastColor
        )
        let content = ActivityContent(state: state, staleDate: nil)
        if let act = Activity<BeerActivityAttributes>.activities.first {
            await act.update(content)
        }
    }
}

struct AddLastBeerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Ещё одну"
    init() {}
    func perform() async throws -> some IntentResult {
        await BeerLiveBridge.quickAddLast()
        return .result()
    }
}
