import SwiftUI

struct AnshSchedulerRootView: View {
    @EnvironmentObject private var navigationState: AnshSchedulerNavigationState
    @EnvironmentObject private var schedulerStore: AnshSchedulerStore
    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore
    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                schedulerStore.refreshReminderSchedulingOnForeground()
            }
        }
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
