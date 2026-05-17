import PhotosUI
import SwiftUI

struct AnshSchedulerTaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.anshSchedulerTheme) private var theme

    let editingTask: AnshScheduledTask?
    let onSave: (AnshScheduledTaskDraft) -> Void

    @State private var taskNameInput: String
    @State private var reminderTimeInput: Date
    @State private var taskImageData: Data?
    @State private var previewImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPreset: AnshSchedulerPresetTaskImage?
    @State private var isPhotoLoading = false
    @State private var isSaving = false
    @State private var frequency: AnshReminderFrequency
    @State private var weeklyWeekday: Int
    @State private var dayOfMonth: Int
    @State private var calendarAnchorDate: Date
    @State private var oneTimeReminderDate: Date

    private let calendar = Calendar.current

    init(editingTask: AnshScheduledTask?, onSave: @escaping (AnshScheduledTaskDraft) -> Void) {
        self.editingTask = editingTask
        self.onSave = onSave

        let initialTime = editingTask?.reminderTime ?? Date()
        _taskNameInput = State(initialValue: editingTask?.name ?? "")
        _reminderTimeInput = State(initialValue: initialTime)
        _taskImageData = State(initialValue: editingTask?.imageData)
        _frequency = State(initialValue: editingTask?.frequency ?? .daily)
        _weeklyWeekday = State(
            initialValue: editingTask?.weeklyWeekday
                ?? Calendar.current.component(.weekday, from: Date())
        )
        _dayOfMonth = State(
            initialValue: editingTask?.dayOfMonth
                ?? Calendar.current.component(.day, from: initialTime)
        )
        _calendarAnchorDate = State(initialValue: initialTime)
        _oneTimeReminderDate = State(initialValue: initialTime)
        _selectedPreset = State(
            initialValue: Self.matchingPreset(for: editingTask?.imageData)
        )
    }

    private static func matchingPreset(for imageData: Data?) -> AnshSchedulerPresetTaskImage? {
        guard let imageData else { return nil }
        return AnshSchedulerPresetTaskImage.allCases.first { preset in
            guard let presetData = preset.pngData() else { return false }
            return presetData == imageData
        }
    }

    private var trimmedTaskName: String {
        taskNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTaskName.isEmpty && !isSaving && !isPhotoLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.screenBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        labeledField(title: "Task Name") {
                            TextField("Enter task name", text: $taskNameInput)
                                .textFieldStyle(.roundedBorder)
                        }

                        labeledField(title: "Task Image") {
                            VStack(alignment: .leading, spacing: 12) {
                                AnshSchedulerPresetImagePicker(
                                    selectedPreset: $selectedPreset,
                                    onSelectPreset: { preset in
                                        selectedPhotoItem = nil
                                        taskImageData = preset.pngData()
                                    }
                                )

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack {
                                        Label("Upload from Photos", systemImage: "photo.on.rectangle")
                                        if isPhotoLoading {
                                            Spacer()
                                            ProgressView()
                                        }
                                    }
                                    .foregroundStyle(theme.primaryText)
                                }
                                .disabled(isPhotoLoading)

                                if let previewImage {
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }

                                if taskImageData != nil {
                                    Button("Remove image", role: .destructive) {
                                        taskImageData = nil
                                        previewImage = nil
                                        selectedPhotoItem = nil
                                        selectedPreset = nil
                                    }
                                    .font(.subheadline)
                                }
                            }
                        }

                        labeledField(title: "Frequency") {
                            Picker("Frequency", selection: $frequency) {
                                ForEach(AnshReminderFrequency.allCases) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.listRowTint)
                            )
                        }

                        frequencySpecificFields

                        if frequency != .oneTime {
                            labeledField(title: "Task Time") {
                                DatePicker(
                                    "Reminder time",
                                    selection: $reminderTimeInput,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.listRowTint)
                                )
                            }
                        }

                        AnshSchedulerPrimaryButton(title: isSaving ? "Saving…" : "SAVE", isEnabled: canSave) {
                            Task { await saveTask() }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(editingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.primaryText)
                }
            }
            .task(id: taskImageData) {
                await refreshPreviewImage()
            }
            .task(id: selectedPhotoItem?.itemIdentifier) {
                await loadSelectedPhotoIfNeeded()
            }
        }
    }

    private func saveTask() async {
        isSaving = true
        defer { isSaving = false }

        await loadSelectedPhotoIfNeeded()
        onSave(buildDraft())
        dismiss()
    }

    private func loadSelectedPhotoIfNeeded() async {
        guard let selectedPhotoItem else { return }

        isPhotoLoading = true
        defer { isPhotoLoading = false }

        guard let rawData = try? await selectedPhotoItem.loadTransferable(type: Data.self) else {
            return
        }

        selectedPreset = nil
        taskImageData = AnshSchedulerImageDecoding.storageData(from: rawData) ?? rawData
    }

    @ViewBuilder
    private var frequencySpecificFields: some View {
        switch frequency {
        case .daily:
            EmptyView()
        case .weekly:
            labeledField(title: "Day of Week") {
                Picker("Day of Week", selection: $weeklyWeekday) {
                    ForEach(AnshSchedulerFormatting.weekdayOptions(calendar: calendar), id: \.weekday) { option in
                        Text(option.label).tag(option.weekday)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.listRowTint)
                )
            }
        case .monthly:
            labeledField(title: "Date of Month") {
                Picker("Date of Month", selection: $dayOfMonth) {
                    ForEach(1 ... 31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.listRowTint)
                )
            }
        case .yearly:
            labeledField(title: "Date (Month & Day)") {
                DatePicker(
                    "Annual date",
                    selection: $calendarAnchorDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.listRowTint)
                )
            }
        case .oneTime:
            labeledField(title: "Date & Time") {
                Group {
                    if editingTask == nil {
                        DatePicker(
                            "One-time reminder",
                            selection: $oneTimeReminderDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        DatePicker(
                            "One-time reminder",
                            selection: $oneTimeReminderDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                .datePickerStyle(.graphical)
                .labelsHidden()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.listRowTint)
                )
            }
        }
    }

    private func buildDraft() -> AnshScheduledTaskDraft {
        let resolvedReminderTime: Date
        let resolvedWeekday: Int?
        let resolvedDayOfMonth: Int?

        switch frequency {
        case .daily:
            resolvedReminderTime = mergeTime(reminderTimeInput, into: Date())
            resolvedWeekday = nil
            resolvedDayOfMonth = nil
        case .weekly:
            resolvedReminderTime = mergeTime(reminderTimeInput, into: Date())
            resolvedWeekday = weeklyWeekday
            resolvedDayOfMonth = nil
        case .monthly:
            resolvedReminderTime = mergeTime(reminderTimeInput, into: Date())
            resolvedWeekday = nil
            resolvedDayOfMonth = dayOfMonth
        case .yearly:
            resolvedReminderTime = mergeTime(reminderTimeInput, into: calendarAnchorDate)
            resolvedWeekday = nil
            resolvedDayOfMonth = calendar.component(.day, from: calendarAnchorDate)
        case .oneTime:
            resolvedReminderTime = oneTimeReminderDate
            resolvedWeekday = nil
            resolvedDayOfMonth = nil
        }

        return AnshScheduledTaskDraft(
            name: trimmedTaskName,
            reminderTime: resolvedReminderTime,
            imageData: taskImageData,
            frequency: frequency,
            weeklyWeekday: resolvedWeekday,
            dayOfMonth: resolvedDayOfMonth
        )
    }

    private func mergeTime(_ timeSource: Date, into dateSource: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: dateSource)
        let time = calendar.dateComponents([.hour, .minute], from: timeSource)
        components.hour = time.hour
        components.minute = time.minute
        components.second = 0
        return calendar.date(from: components) ?? dateSource
    }

    private func refreshPreviewImage() async {
        guard let taskImageData else {
            previewImage = nil
            return
        }
        previewImage = await AnshSchedulerImageDecoding.uiImage(from: taskImageData)
    }

    private func labeledField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.primaryText)
            content()
        }
    }
}
