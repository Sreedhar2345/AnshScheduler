import SwiftUI
import UniformTypeIdentifiers

struct AnshSchedulerSettingsView: View {
    @EnvironmentObject private var schedulerStore: AnshSchedulerStore
    @EnvironmentObject private var navigationState: AnshSchedulerNavigationState
    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore
    @Environment(\.anshSchedulerTheme) private var theme

    @State private var activeSheet: SettingsSheet?
    @State private var isPickingVoiceMemoFile = false

    private static let voiceMemoUploadTypes: [UTType] = [.mpeg4Audio, .mp3, .wav, .aiff, .audio]

    var body: some View {
        ZStack {
            AnshSchedulerBackground()

            List {
                AnshSchedulerSettingsVoiceMemosSection(
                    isPickingVoiceMemoFile: $isPickingVoiceMemoFile,
                    isUploadDisabled: activeSheet != nil
                )

                Section {
                    Button {
                        activeSheet = .newTask
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
                                activeSheet = .edit(task)
                            } label: {
                                taskRowContent(for: task)
                            }
                            .listRowBackground(theme.listRowTint)
                        }
                        .onDelete(perform: deleteTasks)
                    } header: {
                        Text("Edit Existing Tasks")
                            .foregroundStyle(theme.primaryText)
                    } footer: {
                        Text("Tap a task to edit its details, notes, image, voice memo, and schedule.")
                            .foregroundStyle(theme.secondaryText)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .fileImporter(
            isPresented: $isPickingVoiceMemoFile,
            allowedContentTypes: Self.voiceMemoUploadTypes,
            allowsMultipleSelection: false
        ) { result in
            handleVoiceMemoUpload(result)
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .newTask:
                    AnshSchedulerTaskEditorView(editingTask: nil) { draft in
                        schedulerStore.addScheduledTask(draft)
                        navigationState.showHomeAfterTaskSave()
                    }
                case .edit(let task):
                    AnshSchedulerTaskEditorView(editingTask: task) { draft in
                        schedulerStore.updateScheduledTask(id: task.id, with: draft)
                        navigationState.showHomeAfterTaskSave()
                    }
                }
            }
            .environmentObject(voiceMemoStore)
        }
        .onChange(of: activeSheet?.id) { newValue in
            if newValue != nil {
                isPickingVoiceMemoFile = false
            }
        }
        .onAppear {
            voiceMemoStore.reload()
        }
    }

    private func handleVoiceMemoUpload(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                voiceMemoStore.lastImportError = "No file was selected."
                return
            }
            Task { @MainActor in
                await voiceMemoStore.importVoiceMemo(from: url)
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain != NSCocoaErrorDomain || nsError.code != NSUserCancelledError {
                voiceMemoStore.lastImportError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func taskRowContent(for task: AnshScheduledTask) -> some View {
        HStack(spacing: 12) {
            AnshSchedulerTaskAvatar(taskID: task.id, imageData: task.imageData, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)
                Text(AnshSchedulerFormatting.taskSummary(for: task))
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                if let notes = task.trimmedNotes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let id = schedulerStore.scheduledTasks[index].id
            schedulerStore.deleteScheduledTask(id: id)
        }
        Task {
            await AnshSchedulerImageCache.shared.clear()
        }
    }
}

private enum SettingsSheet: Identifiable {
    case newTask
    case edit(AnshScheduledTask)

    var id: String {
        switch self {
        case .newTask:
            return "new-task"
        case .edit(let task):
            return task.id.uuidString
        }
    }
}
