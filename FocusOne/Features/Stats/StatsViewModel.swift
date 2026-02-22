import Foundation
import CoreData

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var monthDays: [MonthGridDay] = []
    @Published var completionRate7: Double = 0
    @Published var completionRate30: Double = 0
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var monthTitle = ""
    @Published var habitIconSymbol: String?

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
            habitIconSymbol = nil
            return
        }

        let habit = entity.toDomain()
        habitIconSymbol = habit.iconSymbol
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
    }
}
