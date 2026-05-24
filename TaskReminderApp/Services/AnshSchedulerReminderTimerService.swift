import Foundation

/// Plays voice memos at each task's configured reminder time while the app process is running.
@MainActor
final class AnshSchedulerReminderTimerService {
    static let shared = AnshSchedulerReminderTimerService()

    private var timer: Timer?
    private var tasks: [AnshScheduledTask] = []

    private init() {}

    /// Reschedules the next in-app alarm. Never plays audio — playback only happens in the timer callback.
    func sync(tasks: [AnshScheduledTask]) {
        self.tasks = tasks
        rescheduleNext()
    }

    private func rescheduleNext() {
        timer?.invalidate()
        timer = nil

        let now = Date()
        guard let nextFireDate = tasks.compactMap({ task in
            task.nextFireDate(after: now)
        }).min(), nextFireDate.timeIntervalSinceNow > 0 else {
            return
        }

        let delay = nextFireDate.timeIntervalSinceNow
        let scheduledTimer = Timer(
            fire: now.addingTimeInterval(delay),
            interval: 0,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScheduledFire(expectedFireDate: nextFireDate)
            }
        }
        RunLoop.main.add(scheduledTimer, forMode: .common)
        timer = scheduledTimer
    }

    private func handleScheduledFire(expectedFireDate: Date) {
        let now = Date()

        // Timer can fire late after backgrounding — never play on app reopen for a missed reminder.
        guard abs(expectedFireDate.timeIntervalSince(now))
            <= AnshSchedulerConstants.reminderVoiceMemoPlaybackWindowSeconds else {
            rescheduleNext()
            return
        }

        for task in tasks where task.voiceMemoSelection != .none {
            guard task.isReminderDueForPlayback(at: now) else { continue }

            let occurrence = task.scheduledOccurrence(containing: now) ?? expectedFireDate
            let fireKey = AnshSchedulerReminderFireKey.make(
                taskID: task.id.uuidString,
                fireDate: occurrence
            )
            _ = AnshSchedulerVoiceMemoPlaybackService.shared.playScheduledReminderVoiceMemo(
                voiceMemoStorageID: task.voiceMemoStorageID,
                fireKey: fireKey,
                scheduledFireDate: occurrence
            )
        }

        rescheduleNext()
    }
}
