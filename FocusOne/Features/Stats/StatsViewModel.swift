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
    @Published var totalCompletions: Int = 0
    @Published var currentMonthCompletionCount: Int = 0
    @Published var currentMonthCompletionRate: Double = 0
    @Published var rolling4WeekCompletionRate: Double = 0
    @Published var bestMonthCompletionCount: Int = 0
    @Published var bestMonthTitle: String = ""
    @Published var advancedInsightText: String = ""
    @Published var consistencyText: String = ""
    @Published var recordCueText: String = ""
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

    func load(allowPremiumThemes: Bool = PremiumGate().canAccess(.customization)) {
        let repository = HabitRepository(context: context)
        let now = Date()
        historyRoutines = buildHistoryRoutines(
            repository: repository,
            currentDate: now,
            allowPremiumIcons: allowPremiumThemes
        )

        guard let entity = repository.fetchActiveHabit() else {
            resetCurrentRoutineStats()
            return
        }

        var habit = entity.toDomain()
        let effectiveIconSymbol = HabitIcon.effectiveSymbol(
            for: habit.iconSymbol,
            canAccessPremiumIcons: allowPremiumThemes
        )
        let effectiveThemeHex = Theme.effectiveThemeHex(
            for: habit.colorHex,
            canAccessPremiumThemes: allowPremiumThemes
        )
        let effectiveCommitmentDays = CommitmentDurationOption.effectiveDurationDays(
            for: habit.commitmentDurationDays,
            canAccessPremiumDuration: allowPremiumThemes
        )

        if effectiveThemeHex != habit.colorHex ||
            effectiveIconSymbol != habit.iconSymbol ||
            effectiveCommitmentDays != habit.commitmentDurationDays {
            let clearsCommitmentDuration = effectiveCommitmentDays == nil && habit.commitmentDurationDays != nil
            repository.updateHabit(
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

        habit.iconSymbol = effectiveIconSymbol
        habitIconSymbol = effectiveIconSymbol
        themeHex = habit.colorHex
        let completions = repository.fetchCompletions(habitId: habit.id)

        currentStreak = streakEngine.currentStreak(habit: habit, completions: completions)
        completionRate7 = streakEngine.completionRate(habit: habit, completions: completions, days: 7)
        completionRate30 = streakEngine.completionRate(habit: habit, completions: completions, days: 30)
        bestStreak = streakEngine.bestStreak(habit: habit, completions: completions)
        totalCompletions = completions.count
        currentMonthCompletionCount = currentMonthCompletionCount(for: completions, now: now)
        currentMonthCompletionRate = currentMonthCompletionRate(for: habit, completions: completions, now: now)
        rolling4WeekCompletionRate = streakEngine.completionRate(habit: habit, completions: completions, days: 28, now: now)
        let bestMonth = bestMonthCompletionMetric(for: completions)
        bestMonthCompletionCount = bestMonth.count
        bestMonthTitle = bestMonth.title
        advancedInsightText = makeAdvancedInsightText()
        consistencyText = makeConsistencyText()
        recordCueText = makeRecordCueText()

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
        currentDate: Date,
        allowPremiumIcons: Bool
    ) -> [RoutineHistorySection] {
        let monthFormatter = DateFormatter()
        monthFormatter.locale = .current
        monthFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        return repository.fetchHistoryHabits().map { entity in
            let habit = entity.toDomain()
            let iconSymbol = HabitIcon.effectiveSymbol(
                for: habit.iconSymbol,
                canAccessPremiumIcons: allowPremiumIcons
            )
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
                iconSymbol: iconSymbol,
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
        totalCompletions = 0
        currentMonthCompletionCount = 0
        currentMonthCompletionRate = 0
        rolling4WeekCompletionRate = 0
        bestMonthCompletionCount = 0
        bestMonthTitle = ""
        advancedInsightText = ""
        consistencyText = ""
        recordCueText = ""
        monthTitle = ""
    }

    private func currentMonthCompletionCount(for completions: [Completion], now: Date) -> Int {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: now)

        return completions.reduce(into: 0) { count, completion in
            let completionComponents = calendar.dateComponents([.year, .month], from: completion.dayKey)
            if completionComponents.year == currentComponents.year,
               completionComponents.month == currentComponents.month {
                count += 1
            }
        }
    }

    private func currentMonthCompletionRate(for habit: Habit, completions: [Completion], now: Date) -> Double {
        let calendar = Calendar.current
        let boundary = DayBoundary(startHour: habit.dayStartHour, calendar: calendar)
        let monthStartComponents = calendar.dateComponents([.year, .month], from: now)
        let monthStart = calendar.date(from: monthStartComponents) ?? now
        let monthStartKey = boundary.dayKey(for: monthStart)
        let todayKey = boundary.dayKey(for: now)
        let elapsedDays = (calendar.dateComponents([.day], from: monthStartKey, to: todayKey).day ?? 0) + 1
        guard elapsedDays > 0 else { return 0 }

        let monthCompletions = currentMonthCompletionCount(for: completions, now: now)
        return Double(monthCompletions) / Double(elapsedDays)
    }

    private func bestMonthCompletionMetric(for completions: [Completion]) -> (count: Int, title: String) {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        let grouped = Dictionary(grouping: completions) { completion in
            let components = calendar.dateComponents([.year, .month], from: completion.dayKey)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }

        guard let best = grouped.max(by: { $0.value.count < $1.value.count }) else {
            return (0, "")
        }

        let parts = best.key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: 1))
        else {
            return (best.value.count, "")
        }

        return (best.value.count, formatter.string(from: date))
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

    private func makeAdvancedInsightText() -> String {
        if currentMonthCompletionCount == 0 {
            return L10n.text("stats.advanced.insight.start")
        }

        let format = L10n.text("stats.advanced.insight.summary")
        let trend = makeConsistencyText()
        return String.localizedStringWithFormat(format, currentMonthCompletionCount, trend)
    }

    private func makeConsistencyText() -> String {
        let delta = currentMonthCompletionRate - rolling4WeekCompletionRate

        if delta > 0.08 {
            return L10n.text("stats.advanced.trend.up")
        }

        if delta < -0.08 {
            return L10n.text("stats.advanced.trend.down")
        }

        return L10n.text("stats.advanced.trend.stable")
    }

    private func makeRecordCueText() -> String {
        guard bestMonthCompletionCount > 0 else {
            return L10n.text("stats.advanced.record.none")
        }

        let gap = bestMonthCompletionCount - currentMonthCompletionCount

        if gap <= 0 {
            return L10n.text("stats.advanced.record.leading")
        }

        if gap <= 3 {
            let format = L10n.text("stats.advanced.record.close")
            return String.localizedStringWithFormat(format, gap)
        }

        let format = L10n.text("stats.advanced.record.best_month")
        return String.localizedStringWithFormat(format, bestMonthTitle)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
