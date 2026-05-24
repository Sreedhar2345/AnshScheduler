import Foundation
import UserNotifications

final class AnshSchedulerNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        var didPlayVoice = false
        let deliveryAge = abs(notification.date.timeIntervalSinceNow)
        if deliveryAge <= AnshSchedulerConstants.reminderVoiceMemoPlaybackWindowSeconds {
            didPlayVoice = await playScheduledReminderIfDue(from: notification)
        }

        if didPlayVoice {
            return [.banner, .list, .badge]
        }
        return [.banner, .list, .badge, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Do not replay voice memos when the user opens the app from a notification.
    }

    @MainActor
    @discardableResult
    private func playScheduledReminderIfDue(from notification: UNNotification) -> Bool {
        guard let parsed = AnshSchedulerReminderFireKey.from(notification: notification),
              parsed.voiceMemoID != nil else {
            return false
        }

        return AnshSchedulerVoiceMemoPlaybackService.shared.playScheduledReminderVoiceMemo(
            voiceMemoStorageID: parsed.voiceMemoID,
            fireKey: parsed.fireKey,
            scheduledFireDate: parsed.scheduledFireDate
        )
    }
}

enum AnshSchedulerNotificationUserInfoKey {
    static let taskID = "ansh.taskID"
    static let voiceMemoID = "ansh.voiceMemoID"
    static let notes = "ansh.notes"
    static let reminderHour = "ansh.reminderHour"
    static let reminderMinute = "ansh.reminderMinute"
}
