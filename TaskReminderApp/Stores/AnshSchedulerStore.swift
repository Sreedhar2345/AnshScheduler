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
        if let userDefaults {
            self.userDefaults = userDefaults
        } else if let suite = UserDefaults(suiteName: AnshSchedulerConstants.userDefaultsSuiteName) {
            self.userDefaults = suite
        } else {
            self.userDefaults = .standard
        }
        self.notificationsEnabled = notificationsEnabled
        scheduledTasks = Self.loadTasks(from: self.userDefaults)

        if notificationsEnabled {
            scheduleNotificationSync()
        }
    }

    func addScheduledTask(_ draft: AnshScheduledTaskDraft) {
        let task = draft.makeTask()
        scheduledTasks.insert(task, at: Self.sortedInsertionIndex(for: task, in: scheduledTasks))
        persistAndSyncNotifications()
    }

    func updateScheduledTask(id: UUID, with draft: AnshScheduledTaskDraft) {
        guard let index = scheduledTasks.firstIndex(where: { $0.id == id }) else { return }
        var updated = draft.makeTask(id: id)
        scheduledTasks.remove(at: index)
        scheduledTasks.insert(updated, at: Self.sortedInsertionIndex(for: updated, in: scheduledTasks))
        persistAndSyncNotifications()
    }

    func deleteScheduledTask(id: UUID) {
        scheduledTasks.removeAll { $0.id == id }
        persistAndSyncNotifications()
    }

    private func persistAndSyncNotifications() {
        if let encoded = try? Self.jsonEncoder.encode(scheduledTasks) {
            userDefaults.set(encoded, forKey: AnshSchedulerConstants.scheduledTasksStorageKey)
        }
        scheduleNotificationSync()
    }

    private func scheduleNotificationSync() {
        guard notificationsEnabled else { return }
        notificationSyncTask?.cancel()
        let snapshot = scheduledTasks
        notificationSyncTask = Task {
            await AnshSchedulerNotificationService.shared.requestAuthorizationIfNeeded()
            await AnshSchedulerNotificationService.shared.syncReminders(for: snapshot)
        }
    }

    private static func loadTasks(from defaults: UserDefaults) -> [AnshScheduledTask] {
        if let data = defaults.data(forKey: AnshSchedulerConstants.scheduledTasksStorageKey),
           let decoded = try? jsonDecoder.decode([AnshScheduledTask].self, from: data) {
            return decoded.sorted { $0.reminderTime < $1.reminderTime }
        }

        if let data = defaults.data(forKey: AnshSchedulerConstants.bundleIdentifier + ".scheduledTasks.v1"),
           let decoded = try? jsonDecoder.decode([AnshScheduledTask].self, from: data) {
            return decoded.sorted { $0.reminderTime < $1.reminderTime }
        }

        if let migrated = migrateLegacyTasks(from: defaults), !migrated.isEmpty {
            if let encoded = try? jsonEncoder.encode(migrated) {
                defaults.set(encoded, forKey: AnshSchedulerConstants.scheduledTasksStorageKey)
            }
            return migrated
        }

        return []
    }

    private static func migrateLegacyTasks(from defaults: UserDefaults) -> [AnshScheduledTask]? {
        let legacyKey = "ansh-scheduler.tasks"
        let candidates: [UserDefaults] = [defaults, .standard]

        for store in candidates {
            guard let data = store.data(forKey: legacyKey),
                  let legacyTasks = try? jsonDecoder.decode([LegacyScheduledTask].self, from: data) else {
                continue
            }
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
