import Foundation
import CoreData

enum OnboardingMode {
    case create
    case edit
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    let mode: OnboardingMode

    @Published var habitName = ""
    @Published var selectedIconSymbol = HabitIcon.defaultSymbol
    @Published var selectedThemeHex = Theme.defaultThemeHex
    @Published var reminderTimes: [Date] = []
    @Published var dayStartHour = 4
    @Published var notificationsEnabled = true
    @Published var errorMessage: String?
    @Published var isSaving = false

    private let context: NSManagedObjectContext
    private let notificationsService: NotificationsService
    private let streakEngine: StreakEngine
    private var activeHabitEntity: HabitEntity?
    private var initialReminderTimes: [ReminderTime] = []
    private var initialNotificationsEnabled = true

    init(context: NSManagedObjectContext,
         mode: OnboardingMode = .create,
         notificationsService: NotificationsService = .shared,
         streakEngine: StreakEngine = StreakEngine()) {
        self.context = context
        self.mode = mode
        self.notificationsService = notificationsService
        self.streakEngine = streakEngine
        configureInitialState()
    }

    func addReminder() {
        guard reminderTimes.count < 2 else { return }
        reminderTimes.append(Date())
    }

    func removeReminder(at index: Int) {
        guard reminderTimes.indices.contains(index) else { return }
        reminderTimes.remove(at: index)
    }

    func save() async -> Bool {
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = L10n.text("onboarding.error.name_required")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        switch mode {
        case .create:
            return await createHabit(named: trimmedName)
        case .edit:
            return await updateHabit(named: trimmedName)
        }
    }

    private func configureInitialState() {
        notificationsEnabled = storedNotificationsEnabled
        initialNotificationsEnabled = notificationsEnabled

        guard mode == .edit else { return }

        let repository = HabitRepository(context: context)
        guard let active = repository.fetchActiveHabit() else { return }

        activeHabitEntity = active
        let habit = active.toDomain()
        habitName = habit.name
        selectedIconSymbol = habit.iconSymbol
        selectedThemeHex = habit.colorHex
        dayStartHour = habit.dayStartHour
        reminderTimes = habit.reminderTimes.compactMap {
            Calendar.current.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: Date())
        }
        initialReminderTimes = habit.reminderTimes.sorted()
    }

    private var storedNotificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: AppStorageKeys.notificationsEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: AppStorageKeys.notificationsEnabled)
    }

    private func createHabit(named name: String) async -> Bool {
        let repository = HabitRepository(context: context)
        let reminderModels = reminderTimes.map { ReminderTime.from(date: $0) }
        let created = repository.createHabit(
            name: name,
            iconSymbol: selectedIconSymbol,
            colorHex: selectedThemeHex,
            dayStartHour: dayStartHour,
            reminderTimes: reminderModels
        )

        let habit = created.toDomain()
        UserDefaults.standard.set(notificationsEnabled, forKey: AppStorageKeys.notificationsEnabled)
        await syncNotifications(for: habit, shouldReschedule: true)
        saveWidgetSnapshot(for: habit, repository: repository)
        return true
    }

    private func updateHabit(named name: String) async -> Bool {
        guard let activeHabitEntity else {
            errorMessage = L10n.text("onboarding.error.no_active_habit")
            return false
        }

        let repository = HabitRepository(context: context)
        let reminderModels = reminderTimes.map { ReminderTime.from(date: $0) }
        repository.updateHabit(
            activeHabitEntity,
            name: name,
            iconSymbol: selectedIconSymbol,
            colorHex: selectedThemeHex,
            dayStartHour: dayStartHour,
            reminderTimes: reminderModels
        )

        let habit = activeHabitEntity.toDomain()
        UserDefaults.standard.set(notificationsEnabled, forKey: AppStorageKeys.notificationsEnabled)

        let reminderSettingsChanged =
            notificationsEnabled != initialNotificationsEnabled ||
            reminderModels.sorted() != initialReminderTimes

        await syncNotifications(for: habit, shouldReschedule: reminderSettingsChanged)
        saveWidgetSnapshot(for: habit, repository: repository)

        initialNotificationsEnabled = notificationsEnabled
        initialReminderTimes = reminderModels.sorted()
        return true
    }

    private func syncNotifications(for habit: Habit, shouldReschedule: Bool) async {
        if notificationsEnabled {
            guard mode == .create || shouldReschedule else { return }
            _ = await notificationsService.requestPermission()
            await notificationsService.scheduleDailyReminders(for: habit)
            return
        }

        if mode == .create || initialNotificationsEnabled {
            await notificationsService.clearReminders()
        }
    }

    private func saveWidgetSnapshot(for habit: Habit, repository: HabitRepository) {
        let completions = repository.fetchCompletions(habitId: habit.id)
        let doneToday = streakEngine.doneToday(habit: habit, completions: completions)
        let streak = streakEngine.currentStreak(habit: habit, completions: completions)

        AppGroupStorage.shared.saveWidgetSnapshot(
            WidgetDataSnapshot(
                habitName: habit.name,
                iconSymbol: habit.iconSymbol,
                currentStreak: streak,
                doneToday: doneToday,
                themeHex: habit.colorHex
            )
        )
    }
}
