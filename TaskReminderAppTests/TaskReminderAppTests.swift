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
                imageData: nil,
                frequency: .daily,
                weeklyWeekday: nil,
                dayOfMonth: nil
            )
        )
        store.addScheduledTask(
            AnshScheduledTaskDraft(
                name: "Second",
                reminderTime: now,
                imageData: Data([0x01]),
                frequency: .weekly,
                weeklyWeekday: 1,
                dayOfMonth: nil
            )
        )

        XCTAssertEqual(store.scheduledTasks.count, 2)
        XCTAssertEqual(store.scheduledTasks.first?.name, "Second")
        XCTAssertEqual(store.scheduledTasks.first?.frequency, .weekly)

        let id = try! XCTUnwrap(store.scheduledTasks.first?.id)
        store.updateScheduledTask(
            id: id,
            with: AnshScheduledTaskDraft(
                name: "Updated",
                reminderTime: later,
                imageData: Data([0x02]),
                frequency: .monthly,
                weeklyWeekday: nil,
                dayOfMonth: 10
            )
        )

        let updated = store.scheduledTasks.first(where: { $0.id == id })
        XCTAssertEqual(updated?.name, "Updated")
        XCTAssertEqual(updated?.frequency, .monthly)
        XCTAssertEqual(updated?.dayOfMonth, 10)

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
                imageData: nil,
                frequency: .daily,
                weeklyWeekday: nil,
                dayOfMonth: nil
            )
        )

        XCTAssertNotNil(defaults.data(forKey: AnshSchedulerConstants.scheduledTasksStorageKey))

        let reloadedStore = AnshSchedulerStore(userDefaults: defaults, notificationsEnabled: false)
        XCTAssertEqual(reloadedStore.scheduledTasks.count, 1)
        XCTAssertEqual(reloadedStore.scheduledTasks.first?.name, "Morning walk")
    }
}
