import ImageIO
import UIKit

enum AnshSchedulerImageDecoding {
    private static let storageMaxPixel: CGFloat = 1024

    /// Converts picker/camera bytes into a downscaled JPEG for persistence and list performance.
    static func storageData(from data: Data) async -> Data? {
        await resizedJPEGData(from: data, maxPixel: storageMaxPixel, quality: 0.82)
    }

    static func uiImage(from data: Data, maxPixel: CGFloat = 512) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: decodeImage(from: data, maxPixel: maxPixel))
            }
        }
    }

    private static func resizedJPEGData(
        from data: Data,
        maxPixel: CGFloat,
        quality: CGFloat
    ) async -> Data? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = decodeImage(from: data, maxPixel: maxPixel) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image.jpegData(compressionQuality: quality))
            }
        }
    }

    private static func decodeImage(from data: Data, maxPixel: CGFloat) -> UIImage? {
        if let image = UIImage(data: data) {
            return image.anshSchedulerScaled(maxPixel: maxPixel)
        }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

private extension UIImage {
    func anshSchedulerScaled(maxPixel: CGFloat) -> UIImage {
        let maxDimension = max(size.width, size.height)
        guard maxDimension > maxPixel, maxDimension > 0 else { return self }

        let scale = maxPixel / maxDimension
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
