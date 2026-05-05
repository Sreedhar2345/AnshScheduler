import PhotosUI
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showAddTask = false
    @State private var editingTask: TaskItem?
    @State private var selectedBackgroundItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            ThemeBackgroundView(
                theme: store.selectedTheme,
                personalBackgroundData: store.personalBackgroundData
            )

            List {
                Section("Tasks") {
                    Button("Create New Task") {
                        showAddTask = true
                    }

                    ForEach(store.tasks) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.name)
                                Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Edit") {
                                editingTask = task
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let id = store.tasks[index].id
                            store.deleteTask(id: id)
                        }
                    }
                }

                Section("Theme") {
                    Picker("Theme", selection: $store.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }

                    if store.selectedTheme == .personal {
                        PhotosPicker(selection: $selectedBackgroundItem, matching: .images) {
                            Label("Upload personal background", systemImage: "photo.on.rectangle")
                        }

                        if let data = store.personalBackgroundData,
                           let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 160)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAddTask) {
            TaskEditorView(originalTask: nil) { name, dueDate, imageData in
                store.addTask(name: name, dueDate: dueDate, imageData: imageData)
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditorView(originalTask: task) { name, dueDate, imageData in
                store.updateTask(id: task.id, name: name, dueDate: dueDate, imageData: imageData)
            }
        }
        .onChange(of: selectedBackgroundItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    store.personalBackgroundData = data
                }
            }
        }
    }
}
