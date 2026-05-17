import UIKit

/// Thread-safe image cache; avoids concurrent `NSCache` access that triggers runtime warnings.
actor AnshSchedulerImageCache {
    static let shared = AnshSchedulerImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 48
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    func image(forKey key: String, loader: () async -> UIImage?) async -> UIImage? {
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }
        guard let image = await loader() else { return nil }
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
        return image
    }

    func clear() {
        cache.removeAllObjects()
    }
}
