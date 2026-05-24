import Foundation

extension AnshScheduledTask {
    private static let schedulingCalendar = Calendar.current

    /// Whether `reference` is within the playback window at the task's configured reminder time.
    func isReminderDueForPlayback(
        at reference: Date = Date(),
        calendar: Calendar = schedulingCalendar
    ) -> Bool {
        isReminderDue(
            at: reference,
            calendar: calendar,
            grace: AnshSchedulerConstants.reminderVoiceMemoPlaybackWindowSeconds
        )
    }

    /// Whether `reference` falls within the task's configured reminder time (hour/minute + frequency).
    func isReminderDue(
        at reference: Date = Date(),
        calendar: Calendar = schedulingCalendar,
        grace: TimeInterval = AnshSchedulerConstants.reminderVoiceMemoFireWindowSeconds
    ) -> Bool {
        guard let occurrence = scheduledOccurrence(containing: reference, calendar: calendar) else {
            return false
        }
        return abs(occurrence.timeIntervalSince(reference)) <= grace
    }

    /// The reminder occurrence that contains `reference`, if any.
    func scheduledOccurrence(
        containing reference: Date,
        calendar: Calendar = schedulingCalendar
    ) -> Date? {
        let grace = AnshSchedulerConstants.reminderVoiceMemoFireWindowSeconds
        let components = notificationDateComponents(calendar: calendar)

        switch frequency {
        case .oneTime:
            guard let date = calendar.date(from: components) else { return nil }
            return abs(date.timeIntervalSince(reference)) <= grace ? date : nil
        default:
            guard let candidate = calendar.nextDate(
                after: reference.addingTimeInterval(-grace - 60),
                matching: components,
                matchingPolicy: .nextTime,
                direction: .forward
            ) else {
                return nil
            }
            return abs(candidate.timeIntervalSince(reference)) <= grace ? candidate : nil
        }
    }

    /// Next time this task should fire its reminder, including the current occurrence if it is due now.
    func nextReminderFireDate(
        from reference: Date = Date(),
        calendar: Calendar = schedulingCalendar
    ) -> Date? {
        if let dueNow = scheduledOccurrence(containing: reference, calendar: calendar) {
            return dueNow
        }

        let components = notificationDateComponents(calendar: calendar)

        switch frequency {
        case .oneTime:
            guard let date = calendar.date(from: components), date > reference else { return nil }
            return date
        default:
            return calendar.nextDate(
                after: reference,
                matching: components,
                matchingPolicy: .nextTime,
                direction: .forward
            )
        }
    }

    /// Next scheduled fire date strictly after `reference` (legacy helper for tests).
    func nextFireDate(after reference: Date = Date(), calendar: Calendar = .current) -> Date? {
        let components = notificationDateComponents(calendar: calendar)

        switch frequency {
        case .oneTime:
            guard let date = calendar.date(from: components), date > reference else { return nil }
            return date
        default:
            return calendar.nextDate(
                after: reference,
                matching: components,
                matchingPolicy: .nextTime,
                direction: .forward
            )
        }
    }
}
