import Foundation

@MainActor
final class AnshSchedulerNavigationState: ObservableObject {
    @Published var selectedTabIndex: Int = 0

    func showHomeAfterTaskSave() {
        selectedTabIndex = 0
    }

    func showSettingsTab() {
        selectedTabIndex = 1
    }
}
