import SwiftUI

struct AnshSchedulerSettingsVoiceMemosSection: View {
    @Binding var isPresentingRecorder: Bool

    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore
    @Environment(\.anshSchedulerTheme) private var theme

    let isActionDisabled: Bool

    var body: some View {
        Section {
            Button {
                isPresentingRecorder = true
            } label: {
                HStack {
                    Label("Add voice memo", systemImage: "mic.fill")
                        .foregroundStyle(theme.primaryText)
                    Spacer()
                    if voiceMemoStore.isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(isActionDisabled || voiceMemoStore.isImporting)
            .listRowBackground(theme.listRowTint)

            if !voiceMemoStore.customMemos.isEmpty {
                ForEach(voiceMemoStore.customMemos) { memo in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(memo.displayName)
                                .foregroundStyle(theme.primaryText)
                            Text("Available for tasks")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            voiceMemoStore.deleteVoiceMemo(id: memo.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .listRowBackground(theme.listRowTint)
                }
            }
        } header: {
            Text("My Voice Memos")
                .foregroundStyle(theme.primaryText)
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Record a voice memo here, then choose it from the Voice Memo menu when creating or editing a task.")
                if voiceMemoStore.isImporting {
                    Text("Saving…")
                        .foregroundStyle(theme.secondaryText)
                }
                if let error = voiceMemoStore.lastImportError {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .foregroundStyle(theme.secondaryText)
        }
    }
}
