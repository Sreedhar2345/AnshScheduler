import Foundation

struct AnshScheduledTask: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var reminderTime: Date
    var imageData: Data?
    var frequency: AnshReminderFrequency
    /// `Calendar` weekday (1 = Sunday … 7 = Saturday). Used when `frequency == .weekly`.
    var weeklyWeekday: Int?
    /// Day of month (1–31). Used when `frequency == .monthly` or `.yearly`.
    var dayOfMonth: Int?

    init(
        id: UUID = UUID(),
        name: String,
        reminderTime: Date,
        imageData: Data? = nil,
        frequency: AnshReminderFrequency = .daily,
        weeklyWeekday: Int? = nil,
        dayOfMonth: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.reminderTime = reminderTime
        self.imageData = imageData
        self.frequency = frequency
        self.weeklyWeekday = weeklyWeekday
        self.dayOfMonth = dayOfMonth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        reminderTime = try container.decode(Date.self, forKey: .reminderTime)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        frequency = try container.decodeIfPresent(AnshReminderFrequency.self, forKey: .frequency) ?? .daily
        weeklyWeekday = try container.decodeIfPresent(Int.self, forKey: .weeklyWeekday)
        dayOfMonth = try container.decodeIfPresent(Int.self, forKey: .dayOfMonth)
    }

    var repeatsReminder: Bool {
        frequency != .oneTime
    }

    func notificationDateComponents(calendar: Calendar = .current) -> DateComponents {
        let timeParts = calendar.dateComponents([.hour, .minute], from: reminderTime)

        switch frequency {
        case .daily:
            var daily = DateComponents()
            daily.hour = timeParts.hour
            daily.minute = timeParts.minute
            return daily
        case .weekly:
            var weekly = DateComponents()
            weekly.hour = timeParts.hour
            weekly.minute = timeParts.minute
            weekly.weekday = weeklyWeekday
            return weekly
        case .monthly:
            var monthly = DateComponents()
            monthly.day = dayOfMonth
            monthly.hour = timeParts.hour
            monthly.minute = timeParts.minute
            return monthly
        case .yearly:
            let monthDay = calendar.dateComponents([.month, .day], from: reminderTime)
            var yearly = DateComponents()
            yearly.month = monthDay.month
            yearly.day = monthDay.day ?? dayOfMonth
            yearly.hour = timeParts.hour
            yearly.minute = timeParts.minute
            return yearly
        case .oneTime:
            return calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderTime
            )
        }
    }
}

struct AnshScheduledTaskDraft: Equatable, Sendable {
    var name: String
    var reminderTime: Date
    var imageData: Data?
    var frequency: AnshReminderFrequency
    var weeklyWeekday: Int?
    var dayOfMonth: Int?

    func makeTask(id: UUID = UUID()) -> AnshScheduledTask {
        AnshScheduledTask(
            id: id,
            name: name,
            reminderTime: reminderTime,
            imageData: imageData,
            frequency: frequency,
            weeklyWeekday: weeklyWeekday,
            dayOfMonth: dayOfMonth
        )
    }
}

extension AnshScheduledTask {
    static func draft(from task: AnshScheduledTask) -> AnshScheduledTaskDraft {
        AnshScheduledTaskDraft(
            name: task.name,
            reminderTime: task.reminderTime,
            imageData: task.imageData,
            frequency: task.frequency,
            weeklyWeekday: task.weeklyWeekday,
            dayOfMonth: task.dayOfMonth
        )
    }
}
