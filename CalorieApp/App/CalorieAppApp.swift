import SwiftUI

@main
struct CalorieAppApp: App {
    @StateObject private var store = Store()

    init() {
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = Theme.acidUIColor
        seg.setTitleTextAttributes([.foregroundColor: Theme.onAccentUIColor, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .appAppearance()
                .tint(Theme.accentPink)
        }
    }
}
