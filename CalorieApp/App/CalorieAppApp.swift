import SwiftUI
import SwiftData

@main
struct CalorieAppApp: App {
    init() {
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = Theme.acidUIColor
        seg.setTitleTextAttributes([.foregroundColor: Theme.onAccentUIColor, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
    }

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
