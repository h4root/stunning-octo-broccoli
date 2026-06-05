import ActivityKit
import Foundation

struct WaterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var ml: Double
        var goal: Double
    }
}
