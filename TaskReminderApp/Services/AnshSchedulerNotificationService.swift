import Foundation
import UserNotifications

actor AnshSchedulerNotificationService {
    static let shared = AnshSchedulerNotificationService()

    private let calendar = Calendar.current

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    func syncReminders(for tasks: [AnshScheduledTask]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral else {
            return
        }

        AnshSchedulerVoiceMemoService.prepareAllCustomSoundsForNotifications()

        let prefix = AnshSchedulerConstants.reminderNotificationIDPrefix

        let pending = await center.pendingNotificationRequests()
        let desiredByID = Dictionary(
            uniqueKeysWithValues: tasks.map { task in
                (prefix + task.id.uuidString, task)
            }
        )
        let legacyPrefixes = [
            prefix,
            AnshSchedulerConstants.legacyDailyReminderNotificationPrefix,
            AnshSchedulerConstants.legacyDailyTaskNotificationPrefix,
        ]
        let managedIDs = Set(
            pending.map(\.identifier).filter { id in
                legacyPrefixes.contains { id.hasPrefix($0) }
            }
        )

        let orphanedIDs = managedIDs.subtracting(desiredByID.keys)
        if !orphanedIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(orphanedIDs))
        }

        let pendingByID = Dictionary(uniqueKeysWithValues: pending.map { ($0.identifier, $0) })

        for (identifier, task) in desiredByID {
            let desiredComponents = task.notificationDateComponents(calendar: calendar)
            let repeats = task.repeatsReminder
            let desiredSound = AnshSchedulerVoiceMemoService.notificationSoundFilename(
                for: task.voiceMemoSelection
            )

            if let existing = pendingByID[identifier],
               notificationMatches(
                existing,
                task: task,
                components: desiredComponents,
                repeats: repeats,
                soundFilename: desiredSound
               ) {
                continue
            }

            center.removePendingNotificationRequests(withIdentifiers: [identifier])

            if task.frequency == .oneTime,
               let fireDate = calendar.date(from: desiredComponents),
               fireDate <= Date() {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = task.name
            if let notes = task.trimmedNotes {
                content.body = notes
            } else {
                content.body = AnshSchedulerFormatting.taskSummary(for: task)
            }
            content.sound = AnshSchedulerVoiceMemoService.notificationSound(for: task.voiceMemoSelection)
            let timeParts = calendar.dateComponents([.hour, .minute], from: task.reminderTime)
            content.userInfo = [
                AnshSchedulerNotificationUserInfoKey.taskID: task.id.uuidString,
                AnshSchedulerNotificationUserInfoKey.voiceMemoID: task.voiceMemoStorageID ?? "",
                AnshSchedulerNotificationUserInfoKey.notes: task.trimmedNotes ?? "",
                AnshSchedulerNotificationUserInfoKey.reminderHour: timeParts.hour ?? 0,
                AnshSchedulerNotificationUserInfoKey.reminderMinute: timeParts.minute ?? 0,
            ]

            let trigger = UNCalendarNotificationTrigger(dateMatching: desiredComponents, repeats: repeats)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func notificationMatches(
        _ request: UNNotificationRequest,
        task: AnshScheduledTask,
        components: DateComponents,
        repeats: Bool,
        soundFilename: String?
    ) -> Bool {
        guard request.content.title == task.name,
              let trigger = request.trigger as? UNCalendarNotificationTrigger else {
            return false
        }

        guard trigger.repeats == repeats else { return false }

        let desiredBody = task.trimmedNotes ?? AnshSchedulerFormatting.taskSummary(for: task)
        guard request.content.body == desiredBody else { return false }

        let existingSound = request.content.userInfo[AnshSchedulerNotificationUserInfoKey.voiceMemoID] as? String ?? ""
        let desiredSound = task.voiceMemoStorageID ?? ""
        guard existingSound == desiredSound else { return false }

        let existingNotes = request.content.userInfo[AnshSchedulerNotificationUserInfoKey.notes] as? String ?? ""
        guard existingNotes == (task.trimmedNotes ?? "") else { return false }

        return componentsMatch(trigger.dateComponents, components, frequency: task.frequency)
    }

    private func componentsMatch(
        _ lhs: DateComponents,
        _ rhs: DateComponents,
        frequency: AnshReminderFrequency
    ) -> Bool {
        switch frequency {
        case .daily:
            return lhs.hour == rhs.hour && lhs.minute == rhs.minute
        case .weekly:
            return lhs.weekday == rhs.weekday && lhs.hour == rhs.hour && lhs.minute == rhs.minute
        case .monthly:
            return lhs.day == rhs.day && lhs.hour == rhs.hour && lhs.minute == rhs.minute
        case .yearly:
            return lhs.month == rhs.month
                && lhs.day == rhs.day
                && lhs.hour == rhs.hour
                && lhs.minute == rhs.minute
        case .oneTime:
            return lhs.year == rhs.year
                && lhs.month == rhs.month
                && lhs.day == rhs.day
                && lhs.hour == rhs.hour
                && lhs.minute == rhs.minute
        }
    }
}
