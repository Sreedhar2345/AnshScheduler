import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published var selectedTheme: AppTheme = .nature {
        didSet { persist() }
    }
    @Published var personalBackgroundData: Data? {
        didSet { persist() }
    }

    private let tasksKey = "task-reminder.tasks"
    private let themeKey = "task-reminder.theme"
    private let personalBackgroundKey = "task-reminder.personal-bg"
    private let defaults: UserDefaults
    private let notificationsEnabled: Bool

    init(userDefaults: UserDefaults = .standard, notificationsEnabled: Bool = true) {
        self.defaults = userDefaults
        self.notificationsEnabled = notificationsEnabled
        load()
        if notificationsEnabled {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.syncNotifications(for: tasks)
        }
    }

    func addTask(name: String, dueDate: Date, imageData: Data?) {
        tasks.append(TaskItem(name: name, dueDate: dueDate, imageData: imageData))
        tasks.sort { $0.dueDate < $1.dueDate }
        persist()
    }

    func updateTask(id: UUID, name: String, dueDate: Date, imageData: Data?) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].name = name
        tasks[index].dueDate = dueDate
        tasks[index].imageData = imageData
        tasks.sort { $0.dueDate < $1.dueDate }
        persist()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    private func load() {
        if let rawTheme = defaults.string(forKey: themeKey), let theme = AppTheme(rawValue: rawTheme) {
            selectedTheme = theme
        }
        personalBackgroundData = defaults.data(forKey: personalBackgroundKey)

        guard let data = defaults.data(forKey: tasksKey) else { return }
        if let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded.sorted { $0.dueDate < $1.dueDate }
        }
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            defaults.set(encoded, forKey: tasksKey)
        }
        defaults.set(selectedTheme.rawValue, forKey: themeKey)
        defaults.set(personalBackgroundData, forKey: personalBackgroundKey)
        if notificationsEnabled {
            NotificationManager.shared.syncNotifications(for: tasks)
        }
    }
}
