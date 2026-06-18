import Foundation

final class BeerActivityManager {
    static let shared = BeerActivityManager()

    func sync(count: Int, lastBeer: Beer?) {}
    func end() {}

    @MainActor
    func reconcileAndSync(_ store: Store) {}
}
