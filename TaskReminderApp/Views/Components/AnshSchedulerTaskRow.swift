import SwiftUI

struct AnshSchedulerTaskRow: View {
    @Environment(\.anshSchedulerTheme) private var theme

    let task: AnshScheduledTask

    var body: some View {
        HStack(spacing: 12) {
            AnshSchedulerTaskAvatar(taskID: task.id, imageData: task.imageData)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                Text(AnshSchedulerFormatting.taskSummary(for: task))
                    .font(.subheadline)
                if let notes = task.trimmedNotes {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(2)
                }
            }
            .foregroundStyle(theme.primaryText)
        }
        .padding(.vertical, 4)
        .listRowBackground(theme.listRowTint)
    }
}
