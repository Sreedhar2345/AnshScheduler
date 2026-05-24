import SwiftUI

struct AnshSchedulerVoiceMemoPicker: View {
    @EnvironmentObject private var voiceMemoStore: AnshSchedulerVoiceMemoStore
    @Environment(\.anshSchedulerTheme) private var theme

    @Binding var selection: AnshSchedulerVoiceMemoSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Voice memo", selection: $selection) {
                Text("None (default sound)")
                    .tag(AnshSchedulerVoiceMemoSelection.none)

                ForEach(AnshSchedulerVoiceMemoCatalog.bundledMemos) { preset in
                    Text(preset.displayName)
                        .tag(AnshSchedulerVoiceMemoSelection.preset(preset))
                }

                ForEach(voiceMemoStore.customMemos) { memo in
                    Text(memo.displayName)
                        .tag(AnshSchedulerVoiceMemoSelection.custom(memo.id))
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

            if voiceMemoStore.customMemos.isEmpty {
                Text("Add voice memos in Settings to use them here.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }

            Button {
                playPreview()
            } label: {
                Label("Preview sound", systemImage: "play.circle")
            }
            .font(.subheadline)
            .foregroundStyle(theme.primaryText)
            .disabled(selection == .none)
        }
        .onAppear {
            voiceMemoStore.reload()
        }
    }

    private func playPreview() {
        AnshSchedulerVoiceMemoPlaybackService.shared.playVoiceMemo(for: selection)
    }
}
