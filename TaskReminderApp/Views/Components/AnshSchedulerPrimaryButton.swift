import SwiftUI

struct AnshSchedulerPrimaryButton: View {
    @Environment(\.anshSchedulerTheme) private var theme

    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.accentButtonForeground)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.accentButtonBackground)
        )
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}
