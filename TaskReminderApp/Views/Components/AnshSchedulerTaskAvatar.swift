import SwiftUI
import UIKit

struct AnshSchedulerTaskAvatar: View {
    @Environment(\.anshSchedulerTheme) private var theme

    let taskID: UUID
    let imageData: Data?
    var size: CGFloat = 48

    @State private var loadedImage: UIImage?

    private var imageCacheTaskID: String {
        "\(taskID.uuidString)-\(imageData?.count ?? 0)"
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(theme.taskIconBackground)
            .frame(width: size, height: size)
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
            .task(id: imageCacheTaskID) {
                await loadImageIfNeeded()
            }
    }

    private func loadImageIfNeeded() async {
        guard let imageData else {
            loadedImage = nil
            return
        }

        let cacheKey = "\(taskID.uuidString)-\(imageData.count)"
        loadedImage = await AnshSchedulerImageCache.shared.image(forKey: cacheKey) {
            await AnshSchedulerImageDecoding.uiImage(from: imageData, maxPixel: 256)
        }
    }
}

extension AnshSchedulerTaskAvatar {
    init(imageData: Data?, size: CGFloat = 48) {
        self.taskID = UUID()
        self.imageData = imageData
        self.size = size
    }
}
