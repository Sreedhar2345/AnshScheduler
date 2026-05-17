import SwiftUI

struct AnshSchedulerTaskRow: View {
    @Environment(\.anshSchedulerTheme) private var theme

    let task: AnshScheduledTask

    var body: some View {
        HStack(spacing: 12) {
            AnshSchedulerTaskAvatar(imageData: task.imageData)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                Text(AnshSchedulerFormatting.taskSummary(for: task))
                    .font(.subheadline)
            }
            .foregroundStyle(theme.primaryText)
        }
        .padding(.vertical, 4)
        .listRowBackground(theme.listRowTint)
    }
}
