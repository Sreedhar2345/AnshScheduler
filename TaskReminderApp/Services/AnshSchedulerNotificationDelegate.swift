import Foundation
import UserNotifications

final class AnshSchedulerNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list, .badge]
    }
}

enum AnshSchedulerNotificationUserInfoKey {
    static let taskID = "ansh.taskID"
    static let voiceMemoID = "ansh.voiceMemoID"
    static let notes = "ansh.notes"
}
