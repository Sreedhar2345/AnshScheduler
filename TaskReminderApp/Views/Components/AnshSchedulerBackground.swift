import SwiftUI

struct AnshSchedulerBackground: View {
    @Environment(\.anshSchedulerTheme) private var theme

    var body: some View {
        theme.screenBackground
            .ignoresSafeArea()
    }
}
