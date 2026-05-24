import Foundation

/// Single access point for this app's isolated UserDefaults suite (never `UserDefaults.standard`).
enum AnshSchedulerPreferences {
    private static var cachedStore: UserDefaults?

    /// App-scoped preferences store keyed by `{bundleId}.preferences`.
    static var shared: UserDefaults {
        if let cachedStore {
            return cachedStore
        }

        let suiteName = AnshSchedulerConstants.userDefaultsSuiteName
        let store = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        migrateLegacyPreferencesIfNeeded(into: store)
        cachedStore = store
        return store
    }

    /// Test-only helper to reset the cached suite between unit tests.
    static func resetCachedStoreForTesting() {
        cachedStore = nil
    }

    /// Copies data from the older personal bundle ID suite into this public app suite once.
    private static func migrateLegacyPreferencesIfNeeded(into store: UserDefaults) {
        guard !store.bool(forKey: AnshSchedulerConstants.legacyPreferencesMigratedKey) else {
            return
        }

        let legacySuiteName = AnshSchedulerConstants.legacyBundleIdentifier + ".preferences"
        guard let legacyStore = UserDefaults(suiteName: legacySuiteName) else {
            store.set(true, forKey: AnshSchedulerConstants.legacyPreferencesMigratedKey)
            return
        }

        let legacy = AnshSchedulerConstants.legacyBundleIdentifier

        let legacyToCurrentKeys = [
            legacy + ".scheduledTasks.v2": AnshSchedulerConstants.scheduledTasksStorageKey,
            legacy + ".scheduledTasks.v1": AnshSchedulerConstants.scheduledTasksStorageKeyV1,
            legacy + ".customVoiceMemos.v1": AnshSchedulerConstants.customVoiceMemosStorageKey,
            legacy + ".legacy.tasks.migrated-from-v0": AnshSchedulerConstants.legacyTasksStorageKey,
            "ansh-scheduler.tasks": AnshSchedulerConstants.legacyTasksStorageKey,
        ]

        for (legacyKey, currentKey) in legacyToCurrentKeys {
            guard store.object(forKey: currentKey) == nil,
                  let value = legacyStore.object(forKey: legacyKey) else {
                continue
            }
            store.set(value, forKey: currentKey)
        }

        store.set(true, forKey: AnshSchedulerConstants.legacyPreferencesMigratedKey)
    }
}
