import XCTest
@testable import TaskReminderApp

final class TaskReminderAppTests: XCTestCase {
    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "TaskReminderAppTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testTaskItemInitialization() {
        let date = Date()
        let task = TaskItem(name: "Test Task", dueDate: date, imageData: nil)

        XCTAssertEqual(task.name, "Test Task")
        XCTAssertEqual(task.dueDate, date)
        XCTAssertNil(task.imageData)
    }

    @MainActor
    func testAddUpdateDeleteTaskFlow() {
        let defaults = makeIsolatedDefaults()
        let store = AppStore(userDefaults: defaults, notificationsEnabled: false)
        let now = Date()
        let later = now.addingTimeInterval(3600)

        store.addTask(name: "First", dueDate: later, imageData: nil)
        store.addTask(name: "Second", dueDate: now, imageData: nil)

        XCTAssertEqual(store.tasks.count, 2)
        XCTAssertEqual(store.tasks.first?.name, "Second")

        let id = try! XCTUnwrap(store.tasks.first?.id)
        let image = Data([0x01, 0x02, 0x03])
        store.updateTask(id: id, name: "Updated", dueDate: later, imageData: image)

        let updated = store.tasks.first(where: { $0.id == id })
        XCTAssertEqual(updated?.name, "Updated")
        XCTAssertEqual(updated?.imageData, image)

        store.deleteTask(id: id)
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertFalse(store.tasks.contains(where: { $0.id == id }))
    }

    @MainActor
    func testThemeAndPersonalBackgroundPersistence() {
        let defaults = makeIsolatedDefaults()
        let store = AppStore(userDefaults: defaults, notificationsEnabled: false)
        let bgData = Data([0xAA, 0xBB, 0xCC])

        store.selectedTheme = .personal
        store.personalBackgroundData = bgData

        let reloadedStore = AppStore(userDefaults: defaults, notificationsEnabled: false)
        XCTAssertEqual(reloadedStore.selectedTheme, .personal)
        XCTAssertEqual(reloadedStore.personalBackgroundData, bgData)
    }
}
