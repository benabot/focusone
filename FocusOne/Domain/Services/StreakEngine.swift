import Foundation

struct MonthGridDay: Identifiable {
    let id: Date
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isCompleted: Bool
}

struct StreakEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func doneToday(habit: Habit, completions: [Completion], now: Date = Date()) -> Bool {
        doneToday(habit: habit, completionDayKeys: completionDayKeys(from: completions), now: now)
    }

    func doneToday(habit: Habit, completionDayKeys: Set<Date>, now: Date = Date()) -> Bool {
        let boundary = DayBoundary(startHour: habit.dayStartHour, calendar: calendar)
        return completionDayKeys.contains(boundary.dayKey(for: now))
    }

    // Return the next done state after a toggle request for "today".
    func toggleDoneToday(habit: Habit, completionDayKeys: Set<Date>, now: Date = Date()) -> Bool {
        !doneToday(habit: habit, completionDayKeys: completionDayKeys, now: now)
    }

    func currentStreak(habit: Habit, completions: [Completion], now: Date = Date()) -> Int {
        currentStreak(habit: habit, completionDayKeys: completionDayKeys(from: completions), now: now)
    }

    func currentStreak(habit: Habit, completionDayKeys: Set<Date>, now: Date = Date()) -> Int {
        let boundary = DayBoundary(startHour: habit.dayStartHour, calendar: calendar)
        let todayKey = boundary.dayKey(for: now)

        if completionDayKeys.contains(todayKey) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: todayKey) ?? todayKey
            return 1 + consecutiveDaysBack(from: yesterday, in: completionDayKeys)
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: todayKey) ?? todayKey
        return consecutiveDaysBack(from: yesterday, in: completionDayKeys)
    }

    func bestStreak(habit: Habit, completions: [Completion]) -> Int {
        bestStreak(habit: habit, completionDayKeys: completionDayKeys(from: completions))
    }

    func bestStreak(habit: Habit, completionDayKeys: Set<Date>) -> Int {
        let sorted = completionDayKeys.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var running = 1
        for index in 1..<sorted.count {
            let prev = sorted[index - 1]
            let expected = calendar.date(byAdding: .day, value: 1, to: prev) ?? prev
            if sorted[index] == expected {
                running += 1
                best = max(best, running)
            } else {
                running = 1
            }
        }
        return best
    }

    func completionRate(habit: Habit, completions: [Completion], days: Int, now: Date = Date()) -> Double {
        completionRate(habit: habit, completionDayKeys: completionDayKeys(from: completions), days: days, now: now)
    }

    func completionRate(habit: Habit, completionDayKeys: Set<Date>, days: Int, now: Date = Date()) -> Double {
        guard days > 0 else { return 0 }
        let boundary = DayBoundary(startHour: habit.dayStartHour, calendar: calendar)
        let todayKey = boundary.dayKey(for: now)

        var doneCount = 0
        for offset in 0..<days {
            guard let key = calendar.date(byAdding: .day, value: -offset, to: todayKey) else { continue }
            if completionDayKeys.contains(key) {
                doneCount += 1
            }
        }
        return Double(doneCount) / Double(days)
    }

    func monthGrid(habit: Habit, completions: [Completion], year: Int, month: Int) -> [MonthGridDay] {
        monthGrid(habit: habit, completionDayKeys: completionDayKeys(from: completions), year: year, month: month)
    }

    func monthGrid(habit: Habit, completionDayKeys: Set<Date>, year: Int, month: Int) -> [MonthGridDay] {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let monthStart = calendar.date(from: comps) else { return [] }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) ?? monthStart
        let boundary = DayBoundary(startHour: habit.dayStartHour, calendar: calendar)

        var days: [MonthGridDay] = []
        for index in 0..<42 {
            guard let date = calendar.date(byAdding: .day, value: index, to: gridStart) else { continue }
            let key = boundary.dayKey(for: date)
            days.append(
                MonthGridDay(
                    id: date,
                    date: date,
                    dayNumber: calendar.component(.day, from: date),
                    isCurrentMonth: calendar.isDate(date, equalTo: monthStart, toGranularity: .month),
                    isCompleted: completionDayKeys.contains(key)
                )
            )
        }
        return days
    }

    private func completionDayKeys(from completions: [Completion]) -> Set<Date> {
        Set(completions.map(\.dayKey))
    }

    private func consecutiveDaysBack(from start: Date, in completionDayKeys: Set<Date>) -> Int {
        var count = 0
        var cursor = start

        while completionDayKeys.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
