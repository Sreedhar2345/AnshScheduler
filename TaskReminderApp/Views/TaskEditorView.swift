import PhotosUI
import SwiftUI
import UIKit

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let originalTask: TaskItem?
    let onSave: (String, Date, Data?) -> Void

    @State private var name: String
    @State private var dueDate: Date
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    init(originalTask: TaskItem?, onSave: @escaping (String, Date, Data?) -> Void) {
        self.originalTask = originalTask
        self.onSave = onSave
        _name = State(initialValue: originalTask?.name ?? "")
        _dueDate = State(initialValue: originalTask?.dueDate ?? Date())
        _imageData = State(initialValue: originalTask?.imageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name", text: $name)
                    DatePicker("Task time", selection: $dueDate)
                }

                Section("Task Image") {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Upload image", systemImage: "photo")
                    }

                    if let imageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 160)
                    }
                }
            }
            .navigationTitle(originalTask == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), dueDate, imageData)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }
}
