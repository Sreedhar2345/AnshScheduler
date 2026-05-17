import Foundation

enum AnshSchedulerFormatting {
    private static let reminderTimeStyle = Date.FormatStyle(date: .omitted, time: .shortened)
    private static let oneTimeStyle = Date.FormatStyle(date: .abbreviated, time: .shortened)
    private static let monthDayStyle = Date.FormatStyle(date: .abbreviated, time: .omitted)

    static func reminderTimeLabel(for date: Date) -> String {
        date.formatted(reminderTimeStyle)
    }

    static func taskSummary(for task: AnshScheduledTask, calendar: Calendar = .current) -> String {
        let time = reminderTimeLabel(for: task.reminderTime)

        switch task.frequency {
        case .daily:
            return "Daily · \(time)"
        case .weekly:
            let weekday = weekdayLabel(for: task.weeklyWeekday, calendar: calendar)
            return "Weekly · \(weekday) · \(time)"
        case .monthly:
            let day = task.dayOfMonth.map(String.init) ?? "—"
            return "Monthly · day \(day) · \(time)"
        case .yearly:
            let monthDay = task.reminderTime.formatted(monthDayStyle)
            return "Yearly · \(monthDay) · \(time)"
        case .oneTime:
            return "One time · \(task.reminderTime.formatted(oneTimeStyle))"
        }
    }

    static func weekdayLabel(for weekday: Int?, calendar: Calendar = .current) -> String {
        guard let weekday, (1 ... 7).contains(weekday) else { return "—" }
        let symbols = calendar.weekdaySymbols
        let index = weekday - 1
        guard symbols.indices.contains(index) else { return "—" }
        return symbols[index]
    }

    static func weekdayOptions(calendar: Calendar = .current) -> [(weekday: Int, label: String)] {
        (1 ... 7).map { weekday in
            (weekday, weekdayLabel(for: weekday, calendar: calendar))
        }
    }
}
