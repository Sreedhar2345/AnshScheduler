import ImageIO
import UIKit

enum AnshSchedulerImageDecoding {
    /// Converts picker/camera bytes into JPEG so tasks persist and decode reliably on Home.
    static func storageData(from data: Data) -> Data? {
        guard let image = decodeImage(from: data) else { return nil }
        return image.jpegData(compressionQuality: 0.85) ?? image.pngData()
    }

    static func uiImage(from data: Data) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            decodeImage(from: data)
        }.value
    }

    private static func decodeImage(from data: Data) -> UIImage? {
        if let image = UIImage(data: data) {
            return image
        }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
