import SwiftUI
import UIKit

struct ThemeBackgroundView: View {
    let theme: AppTheme
    let personalBackgroundData: Data?

    var body: some View {
        Group {
            switch theme {
            case .nature:
                LinearGradient(
                    colors: [Color.green.opacity(0.9), Color.brown.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .water:
                LinearGradient(
                    colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .personal:
                if let personalBackgroundData,
                   let image = UIImage(data: personalBackgroundData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color.gray.opacity(0.9), Color.black.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}
