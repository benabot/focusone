import Foundation
import CoreData

struct HistoryMonthSection: Identifiable {
    let id: String
    let title: String
    let days: [MonthGridDay]
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var monthDays: [MonthGridDay] = []
    @Published var historyMonths: [HistoryMonthSection] = []
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
        guard let entity = repository.fetchActiveHabit() else {
            monthDays = []
            historyMonths = []
            habitIconSymbol = nil
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

        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)
        monthDays = streakEngine.monthGrid(habit: habit, completions: completions, year: year, month: month)

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        monthTitle = formatter.string(from: now)

        historyMonths = buildHistoryMonths(
            habit: habit,
            completions: completions,
            currentDate: now,
            formatter: formatter
        )
    }

    private func buildHistoryMonths(
        habit: Habit,
        completions: [Completion],
        currentDate: Date,
        formatter: DateFormatter
    ) -> [HistoryMonthSection] {
        let calendar = Calendar.current
        var monthSections: [HistoryMonthSection] = []

        guard
            let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: habit.startDate)),
            var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))
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
}
