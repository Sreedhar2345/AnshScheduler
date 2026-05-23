import SwiftUI

struct AnshSchedulerRootView: View {
    @EnvironmentObject private var navigationState: AnshSchedulerNavigationState
    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore

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
        .alert(
            "Voice Memo Saved",
            isPresented: Binding(
                get: { voiceMemoStore.importSuccessConfirmation != nil },
                set: { isPresented in
                    if !isPresented {
                        voiceMemoStore.clearImportSuccessConfirmation()
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                voiceMemoStore.clearImportSuccessConfirmation()
            }
        } message: {
            if let confirmation = voiceMemoStore.importSuccessConfirmation {
                Text(confirmation.message)
            }
        }
    }
}
