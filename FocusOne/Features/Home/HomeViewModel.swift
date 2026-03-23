import Foundation
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var habit: Habit?
    @Published var themeHex: String?
    @Published var doneToday = false
    @Published var currentStreak = 0
    @Published var bestStreak = 0
    @Published var nextReminderText = ""
    @Published var commitmentCompletionState: CommitmentCompletionState?

    private let context: NSManagedObjectContext
    private let streakEngine: StreakEngine
    private var activeHabitEntity: HabitEntity?

    init(context: NSManagedObjectContext,
         streakEngine: StreakEngine = StreakEngine()) {
        self.context = context
        self.streakEngine = streakEngine
    }

    func load(allowPremiumThemes: Bool = PremiumGate().canAccess(.customization)) {
        let repo = HabitRepository(context: context)
        guard let entity = repo.fetchActiveHabit() else {
            habit = nil
            themeHex = nil
            commitmentCompletionState = nil
            return
        }

        activeHabitEntity = entity
        var habit = entity.toDomain()
        let premiumUnlocked = allowPremiumThemes
        let effectiveThemeHex = Theme.effectiveThemeHex(
            for: habit.colorHex,
            canAccessPremiumThemes: allowPremiumThemes
        )
        let effectiveIconSymbol = HabitIcon.effectiveSymbol(
            for: habit.iconSymbol,
            canAccessPremiumIcons: premiumUnlocked
        )
        let effectiveCommitmentDays = CommitmentDurationOption.effectiveDurationDays(
            for: habit.commitmentDurationDays,
            canAccessPremiumDuration: premiumUnlocked
        )

        if effectiveThemeHex != habit.colorHex || effectiveIconSymbol != habit.iconSymbol || effectiveCommitmentDays != habit.commitmentDurationDays {
            let clearsCommitmentDuration = effectiveCommitmentDays == nil && habit.commitmentDurationDays != nil
            repo.updateHabit(
                entity,
                iconSymbol: effectiveIconSymbol,
                colorHex: effectiveThemeHex,
                commitmentDurationDays: effectiveCommitmentDays,
                clearsCommitmentDuration: clearsCommitmentDuration
            )
            habit.colorHex = effectiveThemeHex
            habit.iconSymbol = effectiveIconSymbol
            habit.commitmentDurationDays = effectiveCommitmentDays
        }

        let completions = repo.fetchCompletions(habitId: habit.id)
        let now = Date()

        doneToday = streakEngine.doneToday(habit: habit, completions: completions)
        currentStreak = streakEngine.currentStreak(habit: habit, completions: completions)
        bestStreak = streakEngine.bestStreak(habit: habit, completions: completions)
        nextReminderText = nextReminderDescription(from: habit)
        themeHex = habit.colorHex
        commitmentCompletionState = commitmentCompletionState(for: habit, now: now)
        self.habit = habit

        AppGroupStorage.shared.saveWidgetSnapshot(
            WidgetDataSnapshot(
                habitName: habit.name,
                iconSymbol: habit.iconSymbol,
                currentStreak: currentStreak,
                doneToday: doneToday,
                themeHex: habit.colorHex,
                advancedWidgetsEnabled: PremiumGate().canAccess(.advancedWidgets)
            )
        )
    }

    func toggleDoneToday() {
        guard let activeHabitEntity else { return }
        let repository = HabitRepository(context: context)
        _ = repository.toggleCompletion(for: activeHabitEntity)
        load()
    }

    func archiveCurrentHabit() {
        let repository = HabitRepository(context: context)
        _ = repository.archiveActiveHabit()
        load()
    }

    func continueWithoutCommitment() {
        guard let activeHabitEntity else { return }
        let repository = HabitRepository(context: context)
        repository.updateHabit(activeHabitEntity, clearsCommitmentDuration: true)
        load()
    }

    var todayStatusText: String {
        doneToday ? L10n.text("home.support.done") : L10n.text("home.support.pending")
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

    var commitmentCompletedTitle: String {
        L10n.text("home.commitment.completed.title")
    }

    var commitmentCompletedArchiveTitle: String {
        L10n.text("home.commitment.completed.archive")
    }

    var commitmentCompletedContinueTitle: String {
        L10n.text("home.commitment.completed.keep_going")
    }

    var commitmentCompletedNextTitle: String {
        L10n.text("home.commitment.completed.next_routine")
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
            return reminderText(for: nextToday)
        }

        guard let firstTomorrowDate = sorted.first?.toDate(on: now, calendar: calendar),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: firstTomorrowDate) else {
            return L10n.text("home.next_reminder.none")
        }
        return reminderText(for: tomorrow)
    }

    private func reminderText(for date: Date) -> String {
        let format = L10n.text("home.next_reminder.prefix")
        return String.localizedStringWithFormat(format, timeString(for: date))
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter.string(from: date)
    }

    private func commitmentCompletionState(for habit: Habit, now: Date) -> CommitmentCompletionState? {
        guard let commitmentDurationDays = habit.commitmentDurationDays,
              let endDate = habit.commitmentEndDate,
              now >= endDate else {
            return nil
        }

        let option = CommitmentDurationOption.option(for: commitmentDurationDays)
        return CommitmentCompletionState(durationLabel: L10n.text(option.titleKey))
    }
}

struct CommitmentCompletionState {
    let durationLabel: String
}
