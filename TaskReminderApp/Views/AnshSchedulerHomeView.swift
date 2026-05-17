import SwiftUI

struct AnshSchedulerHomeView: View {
    @EnvironmentObject private var schedulerStore: AnshSchedulerStore
    @EnvironmentObject private var navigationState: AnshSchedulerNavigationState
    @Environment(\.anshSchedulerTheme) private var theme
    @State private var isPresentingNewTaskEditor = false

    var body: some View {
        ZStack {
            AnshSchedulerBackground()

            if schedulerStore.scheduledTasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .navigationTitle(AnshSchedulerConstants.appDisplayName)
        .sheet(isPresented: $isPresentingNewTaskEditor) {
            AnshSchedulerTaskEditorView(editingTask: nil) { draft in
                schedulerStore.addScheduledTask(draft)
                navigationState.showHomeAfterTaskSave()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(theme.primaryText.opacity(0.75))

            Text("No tasks yet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(theme.primaryText)

            Text("Add a task with an image, schedule, and reminder frequency.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.secondaryText)
                .padding(.horizontal, 32)

            AnshSchedulerPrimaryButton(title: "Create Task") {
                isPresentingNewTaskEditor = true
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    private var taskList: some View {
        List {
            ForEach(schedulerStore.scheduledTasks) { task in
                AnshSchedulerTaskRow(task: task)
                    .id("\(task.id.uuidString)-\(task.imageData?.count ?? 0)")
            }
        }
        .scrollContentBackground(.hidden)
    }
}
