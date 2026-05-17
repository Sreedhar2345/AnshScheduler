import Foundation

/// Namespaced identifiers so this app never collides with other apps or shared containers.
enum AnshSchedulerConstants {
    static let appDisplayName = "Ansh's Scheduler"

    static let bundleIdentifier: String = {
        Bundle.main.bundleIdentifier ?? "com.saiansh.TaskReminderApp"
    }()

    static let userDefaultsSuiteName = bundleIdentifier + ".preferences"

    static let scheduledTasksStorageKey = bundleIdentifier + ".scheduledTasks.v2"

    static let reminderNotificationIDPrefix = bundleIdentifier + ".reminder."
}
