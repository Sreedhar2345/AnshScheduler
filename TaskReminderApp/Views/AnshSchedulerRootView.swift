import SwiftUI

struct AnshSchedulerRootView: View {
    @EnvironmentObject private var navigationState: AnshSchedulerNavigationState

    var body: some View {
        TabView(selection: $navigationState.selectedTabIndex) {
            NavigationStack {
                AnshSchedulerHomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                AnshSchedulerSettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(1)
        }
        .anshSchedulerThemed()
    }
}
