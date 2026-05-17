import SwiftUI
import UIKit

struct AnshSchedulerTaskAvatar: View {
    @Environment(\.anshSchedulerTheme) private var theme

    let imageData: Data?
    var size: CGFloat = 48

    @State private var loadedImage: UIImage?

    private var imageCacheKey: String {
        guard let imageData else { return "none" }
        return "\(imageData.count)-\(imageData.hashValue)"
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(theme.taskIconBackground)
            .frame(width: size, height: size)
            .clipped()
            .overlay {
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } else {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(theme.taskIconForeground)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: imageCacheKey) {
                guard let imageData else {
                    loadedImage = nil
                    return
                }
                loadedImage = await AnshSchedulerImageDecoding.uiImage(from: imageData)
            }
    }
}
