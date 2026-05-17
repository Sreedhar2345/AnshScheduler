import SwiftUI

struct AnshSchedulerPresetImagePicker: View {
    @Environment(\.anshSchedulerTheme) private var theme

    @Binding var selectedPreset: AnshSchedulerPresetTaskImage?
    let onSelectPreset: (AnshSchedulerPresetTaskImage) -> Void

    private let thumbnailSize: CGFloat = 88
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose a preset")
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AnshSchedulerPresetTaskImage.allCases) { preset in
                    Button {
                        selectedPreset = preset
                        onSelectPreset(preset)
                    } label: {
                        VStack(spacing: 6) {
                            Image(preset.assetName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: thumbnailSize, height: thumbnailSize)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            selectedPreset == preset ? theme.accentButtonBackground : .clear,
                                            lineWidth: 3
                                        )
                                }

                            Text(preset.displayName)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(theme.primaryText)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
