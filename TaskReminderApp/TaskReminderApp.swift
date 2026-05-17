import SwiftUI
import UserNotifications

@main
struct AnshSchedulerApp: App {
    @StateObject private var schedulerStore = AnshSchedulerStore()
    @StateObject private var navigationState = AnshSchedulerNavigationState()

    private let notificationDelegate = AnshSchedulerNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            AnshSchedulerRootView()
                .environmentObject(schedulerStore)
                .environmentObject(navigationState)
        }
    }
}
