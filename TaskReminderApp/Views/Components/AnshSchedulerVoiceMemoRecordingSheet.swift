import SwiftUI

struct AnshSchedulerVoiceMemoRecordingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore
    @Environment(\.anshSchedulerTheme) private var theme

    @StateObject private var recorder = AnshSchedulerVoiceMemoRecorder()
    @State private var memoName = ""
    @State private var recordedFileURL: URL?
    @State private var permissionMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.screenBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(elapsedLabel)
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                        .monospacedDigit()

                    Text("Record up to \(Int(AnshSchedulerVoiceMemoRecorder.maxRecordingSeconds)) seconds for task reminders.")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let permissionMessage {
                        Text(permissionMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if recordedFileURL == nil {
                        Button {
                            toggleRecording()
                        } label: {
                            Label(
                                recorder.isRecording ? "Stop recording" : "Start recording",
                                systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                            )
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(recorder.isRecording ? .red : theme.accentButtonBackground)
                        .disabled(isSaving)
                    } else {
                        TextField("Voice memo name", text: $memoName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Button {
                            Task { await saveRecording() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(isSaving ? "Saving…" : "Save voice memo")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.accentButtonBackground)
                        .disabled(trimmedName.isEmpty || isSaving)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add Voice Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.discardRecording()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(recorder.isRecording || isSaving)
    }

    private var trimmedName: String {
        memoName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var elapsedLabel: String {
        let total = Int(recorder.elapsedSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func toggleRecording() {
        permissionMessage = nil

        if recorder.isRecording {
            recordedFileURL = recorder.stopRecording()
            if memoName.isEmpty, recordedFileURL != nil {
                memoName = defaultMemoName()
            }
            return
        }

        Task {
            let granted = await recorder.requestMicrophoneAccess()
            guard granted else {
                permissionMessage = "Microphone access is required to record voice memos."
                return
            }

            do {
                try recorder.startRecording()
            } catch {
                permissionMessage = error.localizedDescription
            }
        }
    }

    private func saveRecording() async {
        guard let recordedFileURL, !trimmedName.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        let saved = await voiceMemoStore.importVoiceMemo(
            from: recordedFileURL,
            preferredName: trimmedName
        )

        if saved {
            recorder.discardRecording()
            dismiss()
        } else {
            permissionMessage = voiceMemoStore.lastImportError
                ?? "Could not save this voice memo. Please try again."
        }
    }

    private func defaultMemoName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "Voice memo \(formatter.string(from: Date()))"
    }
}
