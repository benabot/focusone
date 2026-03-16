import Foundation
import CoreData

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = true
    @Published var reminderTimes: [Date] = []
    @Published var dayStartHour = 4
    @Published var selectedThemeHex = Theme.defaultThemeHex
    @Published var iCloudStatus = ""

    private let context: NSManagedObjectContext
    private let notificationsService: NotificationsService
    private let streakEngine: StreakEngine
    private var activeHabitEntity: HabitEntity?

    init(context: NSManagedObjectContext,
         notificationsService: NotificationsService = .shared,
         streakEngine: StreakEngine = StreakEngine()) {
        self.context = context
        self.notificationsService = notificationsService
        self.streakEngine = streakEngine
        self.iCloudStatus = L10n.text("settings.icloud.placeholder")
    }

    func load() {
        refreshICloudStatus()

        let repository = HabitRepository(context: context)
        guard let active = repository.fetchActiveHabit() else { return }

        activeHabitEntity = active
        dayStartHour = Int(active.dayStartHour)
        selectedThemeHex = active.colorHex

        reminderTimes = ReminderTimesCodec.decode(active.reminderTimes).compactMap {
            Calendar.current.date(bySettingHour: $0.hour, minute: $0.minute, second: 0, of: Date())
        }

        if UserDefaults.standard.object(forKey: AppStorageKeys.notificationsEnabled) == nil {
            notificationsEnabled = true
        } else {
            notificationsEnabled = UserDefaults.standard.bool(forKey: AppStorageKeys.notificationsEnabled)
        }
    }

    func addReminder() {
        guard reminderTimes.count < 2 else { return }
        reminderTimes.append(Date())
    }

    func removeReminder(at index: Int) {
        guard reminderTimes.indices.contains(index) else { return }
        reminderTimes.remove(at: index)
    }

    func save() async {
        guard let activeHabitEntity else { return }

        let repository = HabitRepository(context: context)
        let reminderModels = reminderTimes.map { ReminderTime.from(date: $0) }

        repository.updateHabit(
            activeHabitEntity,
            colorHex: selectedThemeHex,
            dayStartHour: dayStartHour,
            reminderTimes: reminderModels
        )

        UserDefaults.standard.set(notificationsEnabled, forKey: AppStorageKeys.notificationsEnabled)

        let habit = activeHabitEntity.toDomain()
        if notificationsEnabled {
            _ = await notificationsService.requestPermission()
            await notificationsService.scheduleDailyReminders(for: habit)
        } else {
            await notificationsService.clearReminders()
        }

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

    var notificationsStatusText: String {
        notificationsEnabled
            ? L10n.text("settings.status.enabled")
            : L10n.text("settings.status.disabled")
    }

    var remindersSummaryText: String {
        guard notificationsEnabled, !reminderTimes.isEmpty else {
            return L10n.text("settings.reminders.summary.none")
        }

        switch reminderTimes.count {
        case 1:
            return L10n.text("settings.reminders.summary.one")
        default:
            let format = L10n.text("settings.reminders.summary.many")
            return String.localizedStringWithFormat(format, reminderTimes.count)
        }
    }

    var reminderTimesText: String {
        reminderTimes
            .sorted()
            .map(formattedTime(for:))
            .joined(separator: ", ")
    }

    var dayStartLabelText: String {
        L10n.dayHourLabel(dayStartHour)
    }

    var selectedThemeName: String {
        let preset = Theme.preset(for: selectedThemeHex)
        return L10n.text(preset.nameKey)
    }

    private func refreshICloudStatus() {
        if FileManager.default.ubiquityIdentityToken != nil {
            iCloudStatus = L10n.text("settings.status.icloud.active")
        } else {
            iCloudStatus = L10n.text("settings.status.icloud.not_configured")
        }
    }

    private func formattedTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
