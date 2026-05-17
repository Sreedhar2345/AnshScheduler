import SwiftUI

@main
struct AnshSchedulerApp: App {
    @StateObject private var schedulerStore = AnshSchedulerStore()
    @StateObject private var navigationState = AnshSchedulerNavigationState()

    var body: some Scene {
        WindowGroup {
            AnshSchedulerRootView()
                .environmentObject(schedulerStore)
                .environmentObject(navigationState)
        }
    }
}
