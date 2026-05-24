import Foundation

@MainActor
final class AnshSchedulerStore: ObservableObject {
    @Published private(set) var scheduledTasks: [AnshScheduledTask] = []

    private let userDefaults: UserDefaults
    private let notificationsEnabled: Bool
    private var notificationSyncTask: Task<Void, Never>?

    private static let jsonEncoder = JSONEncoder()
    private static let jsonDecoder = JSONDecoder()

    init(
        userDefaults: UserDefaults? = nil,
        notificationsEnabled: Bool = true
    ) {
        self.userDefaults = userDefaults ?? AnshSchedulerPreferences.shared
        self.notificationsEnabled = notificationsEnabled
        scheduledTasks = Self.loadTasks(from: self.userDefaults)
    }

    /// Call after notification permission is resolved so reminders are actually registered.
    func startReminderScheduling() {
        AnshSchedulerReminderTimerService.shared.sync(tasks: scheduledTasks)
        scheduleNotificationSync()
    }

    func addScheduledTask(_ draft: AnshScheduledTaskDraft) {
        let task = draft.makeTask()
        scheduledTasks.insert(task, at: Self.sortedInsertionIndex(for: task, in: scheduledTasks))
        persistAndSyncNotifications()
    }

    func updateScheduledTask(id: UUID, with draft: AnshScheduledTaskDraft) {
        guard let index = scheduledTasks.firstIndex(where: { $0.id == id }) else { return }
        let updated = draft.makeTask(id: id)
        scheduledTasks.remove(at: index)
        scheduledTasks.insert(updated, at: Self.sortedInsertionIndex(for: updated, in: scheduledTasks))
        persistAndSyncNotifications()
    }

    func deleteScheduledTask(id: UUID) {
        scheduledTasks.removeAll { $0.id == id }
        persistAndSyncNotifications()
    }

    /// Reschedules timers and notifications when returning to the app (never plays audio).
    func refreshReminderSchedulingOnForeground() {
        AnshSchedulerReminderTimerService.shared.sync(tasks: scheduledTasks)
        scheduleNotificationSync()
    }

    private func persistAndSyncNotifications() {
        if let encoded = try? Self.jsonEncoder.encode(scheduledTasks) {
            userDefaults.set(encoded, forKey: AnshSchedulerConstants.scheduledTasksStorageKey)
        }
        AnshSchedulerReminderTimerService.shared.sync(tasks: scheduledTasks)
        scheduleNotificationSync()
    }

    private func scheduleNotificationSync() {
        guard notificationsEnabled else { return }
        notificationSyncTask?.cancel()
        let snapshot = scheduledTasks
        notificationSyncTask = Task(priority: .utility) {
            _ = await AnshSchedulerNotificationService.shared.requestAuthorizationIfNeeded()
            await AnshSchedulerNotificationService.shared.syncReminders(for: snapshot)
        }
    }

    private static func loadTasks(from defaults: UserDefaults) -> [AnshScheduledTask] {
        if let data = defaults.data(forKey: AnshSchedulerConstants.scheduledTasksStorageKey),
           let decoded = try? jsonDecoder.decode([AnshScheduledTask].self, from: data) {
            return normalizeVoiceMemoIDs(in: decoded)
        }

        if let data = defaults.data(forKey: AnshSchedulerConstants.scheduledTasksStorageKeyV1),
           let decoded = try? jsonDecoder.decode([AnshScheduledTask].self, from: data) {
            let normalized = normalizeVoiceMemoIDs(in: decoded)
            persist(normalized, to: defaults)
            defaults.removeObject(forKey: AnshSchedulerConstants.scheduledTasksStorageKeyV1)
            return normalized
        }

        if let migrated = migrateLegacyTasks(from: defaults), !migrated.isEmpty {
            let normalized = normalizeVoiceMemoIDs(in: migrated)
            persist(normalized, to: defaults)
            return normalized
        }

        return []
    }

    private static func persist(_ tasks: [AnshScheduledTask], to defaults: UserDefaults) {
        if let encoded = try? jsonEncoder.encode(tasks) {
            defaults.set(encoded, forKey: AnshSchedulerConstants.scheduledTasksStorageKey)
        }
    }

    /// Upgrades legacy voice memo IDs to bundle-scoped identifiers.
    private static func normalizeVoiceMemoIDs(in tasks: [AnshScheduledTask]) -> [AnshScheduledTask] {
        tasks.map { task in
            guard let storageID = task.voiceMemoStorageID,
                  let selection = AnshSchedulerVoiceMemoSelection(storageIdentifier: storageID) else {
                return task
            }
            var updated = task
            updated.voiceMemoStorageID = selection.storageIdentifier
            return updated
        }
    }

    private static func migrateLegacyTasks(from defaults: UserDefaults) -> [AnshScheduledTask]? {
        let legacyKeys = [
            AnshSchedulerConstants.legacyTasksStorageKey,
            "ansh-scheduler.tasks",
        ]

        for legacyKey in legacyKeys {
            guard let data = defaults.data(forKey: legacyKey),
                  let legacyTasks = try? jsonDecoder.decode([LegacyScheduledTask].self, from: data) else {
                continue
            }

            defaults.removeObject(forKey: legacyKey)
            return legacyTasks.map {
                AnshScheduledTask(id: $0.id, name: $0.name, reminderTime: $0.dueDate, frequency: .daily)
            }.sorted { $0.reminderTime < $1.reminderTime }
        }

        return nil
    }

    private static func sortedInsertionIndex(for task: AnshScheduledTask, in tasks: [AnshScheduledTask]) -> Int {
        tasks.firstIndex { $0.reminderTime > task.reminderTime } ?? tasks.endIndex
    }
}

private struct LegacyScheduledTask: Codable {
    let id: UUID
    let name: String
    let dueDate: Date
}
