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
        let schedule: String

        switch task.frequency {
        case .daily:
            schedule = "Daily · \(time)"
        case .weekly:
            let weekday = weekdayLabel(for: task.weeklyWeekday, calendar: calendar)
            schedule = "Weekly · \(weekday) · \(time)"
        case .monthly:
            let day = task.dayOfMonth.map(String.init) ?? "—"
            schedule = "Monthly · day \(day) · \(time)"
        case .yearly:
            let monthDay = task.reminderTime.formatted(monthDayStyle)
            schedule = "Yearly · \(monthDay) · \(time)"
        case .oneTime:
            schedule = "One time · \(task.reminderTime.formatted(oneTimeStyle))"
        }

        if let voiceName = AnshSchedulerVoiceMemoService.displayName(for: task.voiceMemoSelection) {
            return "\(schedule) · 🔊 \(voiceName)"
        }
        return schedule
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
