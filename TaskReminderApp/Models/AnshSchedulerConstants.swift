import Foundation

/// Namespaced identifiers so this app never collides with other apps or shared containers.
enum AnshSchedulerConstants {
    static let appDisplayName = "Ansh's Scheduler"

    static let bundleIdentifier: String = {
        Bundle.main.bundleIdentifier ?? "com.anshscheduler.app"
    }()

    // MARK: - UserDefaults (app-private suite)

    static let userDefaultsSuiteName = bundleIdentifier + ".preferences"

    static let scheduledTasksStorageKey = bundleIdentifier + ".scheduledTasks.v2"
    static let scheduledTasksStorageKeyV1 = bundleIdentifier + ".scheduledTasks.v1"
    static let customVoiceMemosStorageKey = bundleIdentifier + ".customVoiceMemos.v1"

    /// Legacy key used only inside this app's preferences suite during one-time migration.
    static let legacyTasksStorageKey = bundleIdentifier + ".legacy.tasks.migrated-from-v0"

    // MARK: - On-disk paths (app sandbox; directory names are bundle-scoped)

    static let applicationSupportDirectoryName = bundleIdentifier + ".data"
    static let voiceMemosDirectoryName = bundleIdentifier + ".voice-memos"
    static let voiceMemoImportTempDirectoryName = bundleIdentifier + ".voice-import-temp"
    static let voiceMemoRecordingTempPrefix = bundleIdentifier + ".recording."
    static let voiceMemoCAFFilePrefix = bundleIdentifier + ".voice."

    // MARK: - Voice memo identifiers persisted on tasks

    static let customVoiceMemoStoragePrefix = bundleIdentifier + ".custom."
    static let presetVoiceMemoStoragePrefix = bundleIdentifier + ".preset."
    static let legacyCustomVoiceMemoStoragePrefix = "custom."
    static let legacyPresetVoiceMemoStoragePrefix = "preset."
    static let legacyVoiceMemosDirectoryName = "VoiceMemos"
    static let legacyVoiceMemoCAFFilePrefix = "ansh-voice-"
    static let legacyVoiceMemoStorageMigratedKey = bundleIdentifier + ".legacyVoiceMemoStorageMigrated.v1"

    // MARK: - Notifications

    static let reminderNotificationIDPrefix = bundleIdentifier + ".reminder."
    static let legacyDailyReminderNotificationPrefix = bundleIdentifier + ".dailyReminder."
    static let legacyDailyTaskNotificationPrefix = bundleIdentifier + ".dailyTask."

    // MARK: - In-memory cache

    static let imageCacheName = bundleIdentifier + ".image-cache"

    // MARK: - Reminder playback

    static let recentlyPlayedReminderKeysKey = bundleIdentifier + ".recentlyPlayedReminderKeys.v1"
    /// Voice memos only play within this tight window at the task's scheduled time.
    static let reminderVoiceMemoPlaybackWindowSeconds: TimeInterval = 15
    /// Wider window used only for matching scheduled occurrences.
    static let reminderVoiceMemoFireWindowSeconds: TimeInterval = 60

    /// Previous personal bundle ID; data is migrated once into the public app suite.
    static let legacyBundleIdentifier = "com.saiansh.TaskReminderApp"
    static let legacyPreferencesMigratedKey = bundleIdentifier + ".legacyPreferencesMigrated.v1"
}
