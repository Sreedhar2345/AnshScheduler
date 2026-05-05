import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
        }
    }

    func syncNotifications(for tasks: [TaskItem]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for task in tasks where task.dueDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = "Task Reminder"
            content.body = task.name
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: task.dueDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: task.id.uuidString,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
