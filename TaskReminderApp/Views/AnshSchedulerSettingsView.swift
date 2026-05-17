import SwiftUI

struct AnshSchedulerSettingsView: View {
    @EnvironmentObject private var schedulerStore: AnshSchedulerStore
    @EnvironmentObject private var navigationState: AnshSchedulerNavigationState
    @Environment(\.anshSchedulerTheme) private var theme

    @State private var isPresentingNewTaskEditor = false
    @State private var editingTask: AnshScheduledTask?

    var body: some View {
        ZStack {
            AnshSchedulerBackground()

            List {
                Section {
                    Button {
                        isPresentingNewTaskEditor = true
                    } label: {
                        Label("Add a New Task", systemImage: "plus.circle.fill")
                            .foregroundStyle(theme.primaryText)
                    }
                    .listRowBackground(theme.listRowTint)
                } header: {
                    Text("Manage Tasks")
                        .foregroundStyle(theme.primaryText)
                }

                if !schedulerStore.scheduledTasks.isEmpty {
                    Section {
                        ForEach(schedulerStore.scheduledTasks) { task in
                            Button {
                                editingTask = task
                            } label: {
                                HStack(spacing: 12) {
                                    AnshSchedulerTaskAvatar(imageData: task.imageData, size: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.name)
                                            .font(.headline)
                                            .foregroundStyle(theme.primaryText)
                                        Text(AnshSchedulerFormatting.taskSummary(for: task))
                                            .font(.subheadline)
                                            .foregroundStyle(theme.secondaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(theme.secondaryText)
                                }
                            }
                            .listRowBackground(theme.listRowTint)
                        }
                        .onDelete(perform: deleteTasks)
                    } header: {
                        Text("Edit Existing Tasks")
                            .foregroundStyle(theme.primaryText)
                    } footer: {
                        Text("Tap a task to edit its image, frequency, and reminder time.")
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $isPresentingNewTaskEditor) {
            AnshSchedulerTaskEditorView(editingTask: nil) { draft in
                schedulerStore.addScheduledTask(draft)
                navigationState.showHomeAfterTaskSave()
            }
        }
        .sheet(item: $editingTask) { task in
            AnshSchedulerTaskEditorView(editingTask: task) { draft in
                schedulerStore.updateScheduledTask(id: task.id, with: draft)
                navigationState.showHomeAfterTaskSave()
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let id = schedulerStore.scheduledTasks[index].id
            schedulerStore.deleteScheduledTask(id: id)
        }
    }
}
