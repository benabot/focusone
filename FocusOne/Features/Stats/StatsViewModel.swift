import Foundation
import CoreData

struct HistoryMonthSection: Identifiable {
    let id: String
    let title: String
    let days: [MonthGridDay]
}

struct RoutineHistorySection: Identifiable {
    let id: UUID
    let name: String
    let iconSymbol: String
    let colorHex: String
    let isActive: Bool
    let periodText: String
    let completionCountText: String
    let currentStreak: Int
    let bestStreak: Int
    let completionRate7: Double
    let completionRate30: Double
    let months: [HistoryMonthSection]
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var monthDays: [MonthGridDay] = []
    @Published var historyRoutines: [RoutineHistorySection] = []
    @Published var completionRate7: Double = 0
    @Published var completionRate30: Double = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var monthTitle = ""
    @Published var habitIconSymbol: String?
    @Published var themeHex: String?

    private let context: NSManagedObjectContext
    private let streakEngine: StreakEngine

    init(context: NSManagedObjectContext,
         streakEngine: StreakEngine = StreakEngine()) {
        self.context = context
        self.streakEngine = streakEngine
    }

    func load() {
        let repository = HabitRepository(context: context)
        let now = Date()
        historyRoutines = buildHistoryRoutines(repository: repository, currentDate: now)

        guard let entity = repository.fetchActiveHabit() else {
            resetCurrentRoutineStats()
            return
        }

        let habit = entity.toDomain()
        habitIconSymbol = habit.iconSymbol
        themeHex = habit.colorHex
        let completions = repository.fetchCompletions(habitId: habit.id)

        currentStreak = streakEngine.currentStreak(habit: habit, completions: completions)
        completionRate7 = streakEngine.completionRate(habit: habit, completions: completions, days: 7)
        completionRate30 = streakEngine.completionRate(habit: habit, completions: completions, days: 30)
        bestStreak = streakEngine.bestStreak(habit: habit, completions: completions)

        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)
        monthDays = streakEngine.monthGrid(habit: habit, completions: completions, year: year, month: month)

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        monthTitle = formatter.string(from: now)
    }

    private func buildHistoryRoutines(
        repository: HabitRepository,
        currentDate: Date
    ) -> [RoutineHistorySection] {
        let monthFormatter = DateFormatter()
        monthFormatter.locale = .current
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        return repository.fetchHistoryHabits().map { entity in
            let habit = entity.toDomain()
            let completions = repository.fetchCompletions(habitId: habit.id)
            let referenceDate = historyReferenceDate(
                for: habit,
                completions: completions,
                repository: repository,
                currentDate: currentDate
            )

            return RoutineHistorySection(
                id: habit.id,
                name: habit.name,
                iconSymbol: habit.iconSymbol,
                colorHex: habit.colorHex,
                isActive: habit.isActive,
                periodText: periodText(for: habit, endDate: referenceDate),
                completionCountText: completionCountText(completions.count),
                currentStreak: streakEngine.currentStreak(habit: habit, completions: completions, now: referenceDate),
                bestStreak: streakEngine.bestStreak(habit: habit, completions: completions),
                completionRate7: streakEngine.completionRate(habit: habit, completions: completions, days: 7, now: referenceDate),
                completionRate30: streakEngine.completionRate(habit: habit, completions: completions, days: 30, now: referenceDate),
                months: buildHistoryMonths(
                    habit: habit,
                    completions: completions,
                    referenceDate: referenceDate,
                    formatter: monthFormatter
                )
            )
        }
    }

    private func buildHistoryMonths(
        habit: Habit,
        completions: [Completion],
        referenceDate: Date,
        formatter: DateFormatter
    ) -> [HistoryMonthSection] {
        let calendar = Calendar.current
        var monthSections: [HistoryMonthSection] = []

        guard
            let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: habit.startDate)),
            var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate))
        else {
            return []
        }

        while cursor >= startMonth {
            let year = calendar.component(.year, from: cursor)
            let month = calendar.component(.month, from: cursor)
            let title = formatter.string(from: cursor).capitalized

            monthSections.append(
                HistoryMonthSection(
                    id: "\(year)-\(month)",
                    title: title,
                    days: streakEngine.monthGrid(habit: habit, completions: completions, year: year, month: month)
                )
            )

            guard let previous = calendar.date(byAdding: .month, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return monthSections
    }

    private func resetCurrentRoutineStats() {
        monthDays = []
        habitIconSymbol = nil
        themeHex = nil
        currentStreak = 0
        bestStreak = 0
        completionRate7 = 0
        completionRate30 = 0
        monthTitle = ""
    }

    private func historyReferenceDate(
        for habit: Habit,
        completions: [Completion],
        repository: HabitRepository,
        currentDate: Date
    ) -> Date {
        if habit.isActive {
            return currentDate
        }

        if let endDate = repository.latestCycleEndDate(habitId: habit.id) {
            return endDate
        }

        if let lastCompletion = completions.map(\.timestamp).max() {
            return lastCompletion
        }

        return habit.startDate
    }

    private func periodText(for habit: Habit, endDate: Date) -> String {
        if habit.isActive {
            let format = L10n.text("stats.full_history.period.active")
            return String.localizedStringWithFormat(format, formattedDate(habit.startDate))
        }

        let format = L10n.text("settings.archives.date_range")
        return String.localizedStringWithFormat(
            format,
            formattedDate(habit.startDate),
            formattedDate(endDate)
        )
    }

    private func completionCountText(_ count: Int) -> String {
        switch count {
        case 0:
            return L10n.text("settings.archives.completions.none")
        case 1:
            return L10n.text("settings.archives.completions.one")
        default:
            let format = L10n.text("settings.archives.completions.other")
            return String.localizedStringWithFormat(format, count)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
