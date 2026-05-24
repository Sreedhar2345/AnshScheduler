import UIKit

/// Thread-safe image cache scoped to this app instance.
actor AnshSchedulerImageCache {
    static let shared = AnshSchedulerImageCache()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.name = AnshSchedulerConstants.imageCacheName
        cache.countLimit = 48
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    func image(forKey key: String, loader: () async -> UIImage?) async -> UIImage? {
        let namespacedKey = Self.namespacedKey(key)
        if let cached = cache.object(forKey: namespacedKey as NSString) {
            return cached
        }
        guard let image = await loader() else { return nil }
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: namespacedKey as NSString, cost: cost)
        return image
    }

    func clear() {
        cache.removeAllObjects()
    }

    private static func namespacedKey(_ key: String) -> String {
        "\(AnshSchedulerConstants.bundleIdentifier).\(key)"
    }
}
