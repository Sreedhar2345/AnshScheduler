import XCTest
@testable import TaskReminderApp

final class AnshSchedulerStoreTests: XCTestCase {
    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "AnshSchedulerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testScheduledTaskNotificationComponents() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 16
        components.hour = 9
        components.minute = 30
        let reminderTime = calendar.date(from: components)!

        let weekly = AnshScheduledTask(
            name: "Weekly",
            reminderTime: reminderTime,
            frequency: .weekly,
            weeklyWeekday: 2
        )
        let weeklyParts = weekly.notificationDateComponents(calendar: calendar)
        XCTAssertEqual(weeklyParts.weekday, 2)
        XCTAssertEqual(weeklyParts.hour, 9)
        XCTAssertEqual(weeklyParts.minute, 30)

        let monthly = AnshScheduledTask(
            name: "Monthly",
            reminderTime: reminderTime,
            frequency: .monthly,
            dayOfMonth: 15
        )
        let monthlyParts = monthly.notificationDateComponents(calendar: calendar)
        XCTAssertEqual(monthlyParts.day, 15)

        let yearly = AnshScheduledTask(
            name: "Yearly",
            reminderTime: reminderTime,
            frequency: .yearly,
            dayOfMonth: 16
        )
        let yearlyParts = yearly.notificationDateComponents(calendar: calendar)
        XCTAssertEqual(yearlyParts.month, 5)
        XCTAssertEqual(yearlyParts.day, 16)
    }

    func testNotesTrimming() {
        let task = AnshScheduledTask(
            name: "Test",
            reminderTime: Date(),
            notes: "  Remember keys  "
        )
        XCTAssertEqual(task.trimmedNotes, "Remember keys")
    }

    @MainActor
    func testAddUpdateDeleteTaskFlow() {
        let defaults = makeIsolatedDefaults()
        let store = AnshSchedulerStore(userDefaults: defaults, notificationsEnabled: false)
        let now = Date()
        let later = now.addingTimeInterval(3600)

        store.addScheduledTask(
            AnshScheduledTaskDraft(
                name: "First",
                reminderTime: later,
                notes: "Pack lunch",
                imageData: nil,
                frequency: .daily,
                weeklyWeekday: nil,
                dayOfMonth: nil,
                voiceMemoSelection: .preset(.wakeUp)
            )
        )
        store.addScheduledTask(
            AnshScheduledTaskDraft(
                name: "Second",
                reminderTime: now,
                notes: "",
                imageData: Data([0x01]),
                frequency: .weekly,
                weeklyWeekday: 1,
                dayOfMonth: nil,
                voiceMemoSelection: .none
            )
        )

        XCTAssertEqual(store.scheduledTasks.count, 2)
        XCTAssertEqual(store.scheduledTasks.first?.name, "Second")

        let id = try! XCTUnwrap(store.scheduledTasks.first?.id)
        store.updateScheduledTask(
            id: id,
            with: AnshScheduledTaskDraft(
                name: "Updated",
                reminderTime: later,
                notes: "Updated note",
                imageData: Data([0x02]),
                frequency: .monthly,
                weeklyWeekday: nil,
                dayOfMonth: 10,
                voiceMemoSelection: .none
            )
        )

        let updated = store.scheduledTasks.first(where: { $0.id == id })
        XCTAssertEqual(updated?.name, "Updated")
        XCTAssertEqual(updated?.trimmedNotes, "Updated note")

        store.deleteScheduledTask(id: id)
        XCTAssertEqual(store.scheduledTasks.count, 1)
    }

    @MainActor
    func testTaskPersistenceUsesNamespacedKey() {
        let defaults = makeIsolatedDefaults()
        let store = AnshSchedulerStore(userDefaults: defaults, notificationsEnabled: false)

        store.addScheduledTask(
            AnshScheduledTaskDraft(
                name: "Morning walk",
                reminderTime: Date(),
                notes: "Bring water",
                imageData: nil,
                frequency: .daily,
                weeklyWeekday: nil,
                dayOfMonth: nil,
                voiceMemoSelection: .none
            )
        )

        XCTAssertNotNil(defaults.data(forKey: AnshSchedulerConstants.scheduledTasksStorageKey))

        let reloadedStore = AnshSchedulerStore(userDefaults: defaults, notificationsEnabled: false)
        XCTAssertEqual(reloadedStore.scheduledTasks.count, 1)
        XCTAssertEqual(reloadedStore.scheduledTasks.first?.trimmedNotes, "Bring water")
    }

    func testVoiceMemoStorageUsesBundleScopedPrefixes() {
        let preset = AnshSchedulerBundledVoiceMemo.wakeUp
        XCTAssertTrue(preset.storageID.hasPrefix(AnshSchedulerConstants.presetVoiceMemoStoragePrefix))

        let customID = UUID()
        let selection = AnshSchedulerVoiceMemoSelection.custom(customID)
        XCTAssertEqual(
            selection.storageIdentifier,
            AnshSchedulerConstants.customVoiceMemoStoragePrefix + customID.uuidString
        )

        XCTAssertEqual(
            AnshSchedulerVoiceMemoSelection(storageIdentifier: "custom.\(customID.uuidString)"),
            .custom(customID)
        )
    }

    func testNextFireDateForDailyTask() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var referenceComponents = DateComponents()
        referenceComponents.year = 2026
        referenceComponents.month = 5
        referenceComponents.day = 23
        referenceComponents.hour = 13
        referenceComponents.minute = 0
        let reference = calendar.date(from: referenceComponents)!

        var reminderComponents = referenceComponents
        reminderComponents.hour = 14
        let reminderTime = calendar.date(from: reminderComponents)!

        let task = AnshScheduledTask(
            name: "Daily",
            reminderTime: reminderTime,
            frequency: .daily
        )

        let next = task.nextReminderFireDate(from: reference, calendar: calendar)
        let nextParts = calendar.dateComponents([.day, .hour, .minute], from: try! XCTUnwrap(next))
        XCTAssertEqual(nextParts.day, 23)
        XCTAssertEqual(nextParts.hour, 14)
        XCTAssertEqual(nextParts.minute, 0)
    }

    func testIsReminderDueWithinGraceWindow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var reminderComponents = DateComponents()
        reminderComponents.year = 2026
        reminderComponents.month = 5
        reminderComponents.day = 23
        reminderComponents.hour = 9
        reminderComponents.minute = 0
        let reminderTime = calendar.date(from: reminderComponents)!

        let task = AnshScheduledTask(
            name: "Morning",
            reminderTime: reminderTime,
            frequency: .daily,
            voiceMemoStorageID: AnshSchedulerVoiceMemoSelection.preset(.wakeUp).storageIdentifier
        )

        var dueReference = reminderComponents
        dueReference.second = 10
        let dueDate = calendar.date(from: dueReference)!

        XCTAssertTrue(task.isReminderDueForPlayback(at: dueDate, calendar: calendar))

        var lateReference = reminderComponents
        lateReference.second = 45
        let lateDate = calendar.date(from: lateReference)!
        XCTAssertFalse(task.isReminderDueForPlayback(at: lateDate, calendar: calendar))
    }
}
