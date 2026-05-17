import SwiftUI

struct AnshSchedulerSettingsVoiceMemosSection: View {
    @Binding var isPickingVoiceMemoFile: Bool

    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore
    @Environment(\.anshSchedulerTheme) private var theme

    let isUploadDisabled: Bool

    var body: some View {
        Section {
            Button {
                isPickingVoiceMemoFile = true
            } label: {
                HStack {
                    Label("Upload voice memo", systemImage: "square.and.arrow.up")
                        .foregroundStyle(theme.primaryText)
                    Spacer()
                    if voiceMemoStore.isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(isUploadDisabled || voiceMemoStore.isImporting)
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
            Text("Custom Voice Memos")
                .foregroundStyle(theme.primaryText)
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tap Upload voice memo, then choose an audio file from Files (m4a, mp3, wav).")
                if voiceMemoStore.isImporting {
                    Text("Importing…")
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
