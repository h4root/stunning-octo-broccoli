import SwiftUI
import SwiftData

@main
struct CalorieAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .appAppearance()
                .tint(Theme.accentPink)
        }
        .modelContainer(for: [FoodEntry.self, SavedFood.self, WaterLog.self, BeerLog.self,
                              CustomCounter.self, CustomCounterLog.self])
    }
}
