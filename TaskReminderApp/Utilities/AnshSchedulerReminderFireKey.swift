import Foundation
import UserNotifications

enum AnshSchedulerReminderFireKey {
    static func make(taskID: String, fireDate: Date) -> String {
        let minuteBucket = Int(fireDate.timeIntervalSince1970 / 60)
        return "\(taskID)-\(minuteBucket)"
    }

    static func from(notification: UNNotification) -> (
        taskID: String,
        voiceMemoID: String?,
        fireKey: String,
        scheduledFireDate: Date
    )? {
        let userInfo = notification.request.content.userInfo
        guard let taskID = userInfo[AnshSchedulerNotificationUserInfoKey.taskID] as? String,
              !taskID.isEmpty else {
            return nil
        }

        let rawVoiceMemoID = userInfo[AnshSchedulerNotificationUserInfoKey.voiceMemoID] as? String
        let voiceMemoID = rawVoiceMemoID?.isEmpty == true ? nil : rawVoiceMemoID

        let scheduledFireDate = scheduledFireDate(from: notification)
        return (
            taskID,
            voiceMemoID,
            make(taskID: taskID, fireDate: scheduledFireDate),
            scheduledFireDate
        )
    }

    /// Reconstructs the task's configured reminder time on the day the notification was delivered.
    private static func scheduledFireDate(from notification: UNNotification) -> Date {
        let userInfo = notification.request.content.userInfo
        let calendar = Calendar.current
        let delivered = notification.date

        if let hour = intValue(from: userInfo[AnshSchedulerNotificationUserInfoKey.reminderHour]),
           let minute = intValue(from: userInfo[AnshSchedulerNotificationUserInfoKey.reminderMinute]) {
            var components = calendar.dateComponents([.year, .month, .day], from: delivered)
            components.hour = hour
            components.minute = minute
            components.second = 0
            if let configured = calendar.date(from: components) {
                return configured
            }
        }

        return delivered
    }

    private static func intValue(from value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }
}
