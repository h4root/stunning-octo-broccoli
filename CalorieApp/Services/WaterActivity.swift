import Foundation
import ActivityKit

struct WaterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var ml: Double
        var goal: Double
    }
}

final class WaterActivityManager {
    static let shared = WaterActivityManager()
    private var activity: Activity<WaterActivityAttributes>?

    func update(ml: Double, goal: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let state = WaterActivityAttributes.ContentState(ml: ml, goal: goal)
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity {
            Task { await activity.update(content) }
            return
        }
        // Завершилась? — поищем активную.
        if let running = Activity<WaterActivityAttributes>.activities.first {
            activity = running
            Task { await running.update(content) }
            return
        }
        do {
            activity = try Activity.request(attributes: WaterActivityAttributes(), content: content, pushType: nil)
        } catch {
            // Виджет-расширение не установлено или активности выключены — тихо игнорируем.
        }
    }

    func end() {
        let running = activity ?? Activity<WaterActivityAttributes>.activities.first
        Task { await running?.end(nil, dismissalPolicy: .immediate) }
        activity = nil
    }
}
