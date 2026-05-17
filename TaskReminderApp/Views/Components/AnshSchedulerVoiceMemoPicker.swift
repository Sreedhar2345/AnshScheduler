import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct AnshSchedulerVoiceMemoPicker: View {
    @Environment(\.anshSchedulerTheme) private var theme

    @Binding var selection: AnshSchedulerVoiceMemoSelection
    @State private var isImportingVoiceMemo = false
    @State private var importErrorMessage: String?
    @State private var previewPlayer: AVAudioPlayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a voice memo")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText)

            Picker("Voice memo", selection: $selection) {
                Text("None (default sound)").tag(AnshSchedulerVoiceMemoSelection.none)

                Section("Built-in") {
                    ForEach(AnshSchedulerVoiceMemoCatalog.bundledMemos) { preset in
                        Text(preset.displayName).tag(AnshSchedulerVoiceMemoSelection.preset(preset))
                    }
                }

                if !AnshSchedulerVoiceMemoService.customVoiceMemos().isEmpty {
                    Section("Imported") {
                        ForEach(AnshSchedulerVoiceMemoService.customVoiceMemos()) { memo in
                            Text(memo.displayName).tag(AnshSchedulerVoiceMemoSelection.custom(memo.id))
                        }
                    }
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

            HStack(spacing: 12) {
                Button {
                    playPreview()
                } label: {
                    Label("Preview", systemImage: "play.circle")
                }
                .disabled(selection == .none)

                Button {
                    isImportingVoiceMemo = true
                } label: {
                    Label("Import voice memo", systemImage: "square.and.arrow.down")
                }
            }
            .font(.subheadline)
            .foregroundStyle(theme.primaryText)

            if let importErrorMessage {
                Text(importErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .fileImporter(
            isPresented: $isImportingVoiceMemo,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importVoiceMemo(from: url)
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
    }

    private func playPreview() {
        guard let url = AnshSchedulerVoiceMemoService.previewURL(for: selection) else { return }
        do {
            previewPlayer = try AVAudioPlayer(contentsOf: url)
            previewPlayer?.play()
        } catch {
            importErrorMessage = "Could not play preview."
        }
    }

    private func importVoiceMemo(from url: URL) {
        do {
            let memo = try AnshSchedulerVoiceMemoService.importCustomVoiceMemo(
                from: url,
                preferredName: nil
            )
            selection = .custom(memo.id)
            importErrorMessage = nil
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

private extension UTType {
    static var mp3: UTType { UTType(filenameExtension: "mp3") ?? .audio }
}
