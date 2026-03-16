import Foundation
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var habit: Habit?
    @Published var doneToday = false
    @Published var currentStreak = 0
    @Published var bestStreak = 0
    @Published var nextReminderText = ""
    @Published var completionRate7: Double = 0

    private let context: NSManagedObjectContext
    private let streakEngine: StreakEngine
    private var activeHabitEntity: HabitEntity?

    init(context: NSManagedObjectContext,
         streakEngine: StreakEngine = StreakEngine()) {
        self.context = context
        self.streakEngine = streakEngine
    }

    func load() {
        let repo = HabitRepository(context: context)
        guard let entity = repo.fetchActiveHabit() else {
            habit = nil
            return
        }

        activeHabitEntity = entity
        let habit = entity.toDomain()
        let completions = repo.fetchCompletions(habitId: habit.id)

        doneToday = streakEngine.doneToday(habit: habit, completions: completions)
        currentStreak = streakEngine.currentStreak(habit: habit, completions: completions)
        bestStreak = streakEngine.bestStreak(habit: habit, completions: completions)
        completionRate7 = streakEngine.completionRate(habit: habit, completions: completions, days: 7)
        nextReminderText = nextReminderDescription(from: habit)
        self.habit = habit

        AppGroupStorage.shared.saveWidgetSnapshot(
            WidgetDataSnapshot(
                habitName: habit.name,
                iconSymbol: habit.iconSymbol,
                currentStreak: currentStreak,
                doneToday: doneToday,
                themeHex: habit.colorHex
            )
        )
    }

    func toggleDoneToday() {
        guard let activeHabitEntity else { return }
        let repository = HabitRepository(context: context)
        _ = repository.toggleCompletion(for: activeHabitEntity)
        load()
    }

    var todayStatusText: String {
        doneToday ? L10n.text("home.today.done") : L10n.text("home.today.not_done")
    }

    var todayStatusShort: String {
        doneToday ? L10n.text("home.today.state.done") : L10n.text("home.today.state.not_done")
    }

    var currentStreakText: String {
        L10n.streakDays(currentStreak)
    }

    var bestStreakText: String {
        L10n.streakDays(bestStreak)
    }

    private func nextReminderDescription(from habit: Habit) -> String {
        guard !habit.reminderTimes.isEmpty else {
            return L10n.text("home.next_reminder.none")
        }

        let calendar = Calendar.current
        let now = Date()
        let sorted = habit.reminderTimes.sorted()

        let todayCandidates = sorted.compactMap { $0.toDate(on: now, calendar: calendar) }
        if let nextToday = todayCandidates.first(where: { $0 > now }) {
            return timeString(for: nextToday)
        }

        guard let firstTomorrowDate = sorted.first?.toDate(on: now, calendar: calendar),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: firstTomorrowDate) else {
            return L10n.text("home.next_reminder.none")
        }
        return timeString(for: tomorrow)
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
