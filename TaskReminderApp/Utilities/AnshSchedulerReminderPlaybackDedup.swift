import Foundation

/// Prevents the same reminder from playing twice when both a timer and notification fire.
enum AnshSchedulerReminderPlaybackDedup {
    private static let retentionInterval: TimeInterval = 10 * 60

    private static var preferences: UserDefaults {
        AnshSchedulerPreferences.shared
    }

    static func shouldPlay(fireKey: String) -> Bool {
        var played = loadPlayedTimestamps()
        prune(&played)

        if played[fireKey] != nil {
            return false
        }

        played[fireKey] = Date().timeIntervalSince1970
        savePlayedTimestamps(played)
        return true
    }

    private static func loadPlayedTimestamps() -> [String: TimeInterval] {
        preferences.dictionary(forKey: AnshSchedulerConstants.recentlyPlayedReminderKeysKey) as? [String: TimeInterval] ?? [:]
    }

    private static func savePlayedTimestamps(_ played: [String: TimeInterval]) {
        preferences.set(played, forKey: AnshSchedulerConstants.recentlyPlayedReminderKeysKey)
    }

    private static func prune(_ played: inout [String: TimeInterval]) {
        let cutoff = Date().timeIntervalSince1970 - retentionInterval
        played = played.filter { $0.value >= cutoff }
    }
}
