import Foundation

struct DayBoundary {
    let startHour: Int
    let calendar: Calendar

    init(startHour: Int, calendar: Calendar = .current) {
        self.startHour = max(0, min(23, startHour))
        self.calendar = calendar
    }

    // A day is [startHour, startHour + 24h). This returns the normalized key for persistence.
    func dayKey(for date: Date) -> Date {
        let anchor = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
        if date < anchor {
            return calendar.date(byAdding: .day, value: -1, to: anchor) ?? anchor
        }
        return anchor
    }

    func nextDayStart(after date: Date) -> Date {
        let key = dayKey(for: date)
        return calendar.date(byAdding: .day, value: 1, to: key) ?? key
    }
}
