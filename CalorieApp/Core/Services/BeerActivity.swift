import Foundation
import ActivityKit
import SwiftData

final class BeerActivityManager {
    static let shared = BeerActivityManager()
    private var activity: Activity<BeerActivityAttributes>?

    func sync(count: Int, lastBeer: Beer?) {
        BeerLiveStore.count = count
        if let b = lastBeer {
            BeerLiveStore.lastBrand = b.name
            BeerLiveStore.lastColor = b.colorHex
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let brand = lastBeer?.name ?? BeerLiveStore.lastBrand
        let color = lastBeer?.colorHex ?? BeerLiveStore.lastColor
        let state = BeerActivityAttributes.ContentState(count: count, lastBrand: brand, colorHex: color)
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity {
            Task { await activity.update(content) }
            return
        }
        if let running = Activity<BeerActivityAttributes>.activities.first {
            activity = running
            Task { await running.update(content) }
            return
        }
        guard count > 0 else { return }
        do {
            activity = try Activity.request(attributes: BeerActivityAttributes(), content: content, pushType: nil)
        } catch {
        }
    }

    func end() {
        let running = activity ?? Activity<BeerActivityAttributes>.activities.first
        Task { await running?.end(nil, dismissalPolicy: .immediate) }
        activity = nil
    }

    @MainActor
    func reconcileAndSync(_ context: ModelContext) {
        let pending = BeerLiveStore.pending
        let today = Calendar.current.startOfDay(for: Date())
        if !pending.isEmpty {
            for brand in pending {
                let abv = BeerCatalog.find(brand)?.abv ?? 4.5
                context.insert(BeerLog(day: today, brand: brand, ml: 500, abv: abv))
            }
            BeerLiveStore.pending = []
            try? context.save()
        }
        let desc = FetchDescriptor<BeerLog>(
            predicate: #Predicate { $0.day == today },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let logs = (try? context.fetch(desc)) ?? []
        let last = BeerCatalog.find(logs.first?.brand ?? "")
        sync(count: logs.count, lastBeer: last)
    }
}
