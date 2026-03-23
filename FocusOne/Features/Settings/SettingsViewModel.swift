import Foundation
import CoreData

struct ArchivedRoutineSummary: Identifiable {
    let id: UUID
    let name: String
    let iconSymbol: String
    let colorHex: String
    let periodText: String
    let detailsText: String
}

struct UpcomingRoutineSummary: Identifiable {
    let id: UUID
    let name: String
    let iconSymbol: String
    let colorHex: String
    let remindersText: String
    let dayStartText: String
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = true
    @Published var reminderTimes: [Date] = []
    @Published var dayStartHour = 4
    @Published var selectedThemeHex = Theme.defaultThemeHex
    @Published var iCloudStatus = ""
    @Published private(set) var archivedRoutines: [ArchivedRoutineSummary] = []
    @Published private(set) var upcomingRoutines: [UpcomingRoutineSummary] = []
    @Published private(set) var premiumAccessState: PremiumAccessState = PremiumGate().accessState()

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

    func load(
        allowPremiumThemes: Bool = PremiumGate().canAccess(.customization),
        storeKitState: PremiumEntitlementState = .unknown
    ) {
        let allowPremiumIcons = PremiumGate(storeKitEntitlementState: storeKitState).canAccess(.customization)
        refreshICloudStatus()
        refreshPremiumState(storeKitState: storeKitState)
        loadArchivedRoutines(allowPremiumIcons: allowPremiumIcons)
        loadUpcomingRoutines(allowPremiumIcons: allowPremiumIcons)

        let repository = HabitRepository(context: context)
        guard let active = repository.fetchActiveHabit() else {
            activeHabitEntity = nil
            reminderTimes = []
            dayStartHour = 4
            selectedThemeHex = Theme.defaultThemeHex
            return
        }

        activeHabitEntity = active
        var habit = active.toDomain()
        let effectiveIconSymbol = HabitIcon.effectiveSymbol(
            for: habit.iconSymbol,
            canAccessPremiumIcons: allowPremiumIcons
        )
        let effectiveThemeHex = Theme.effectiveThemeHex(
            for: active.colorHex,
            canAccessPremiumThemes: allowPremiumThemes
        )
        let effectiveCommitmentDays = CommitmentDurationOption.effectiveDurationDays(
            for: habit.commitmentDurationDays,
            canAccessPremiumDuration: allowPremiumIcons
        )

        if effectiveThemeHex != habit.colorHex ||
            effectiveIconSymbol != habit.iconSymbol ||
            effectiveCommitmentDays != habit.commitmentDurationDays {
            let clearsCommitmentDuration = effectiveCommitmentDays == nil && habit.commitmentDurationDays != nil
            repository.updateHabit(
                active,
                iconSymbol: effectiveIconSymbol,
                colorHex: effectiveThemeHex,
                commitmentDurationDays: effectiveCommitmentDays,
                clearsCommitmentDuration: clearsCommitmentDuration
            )
            habit.colorHex = effectiveThemeHex
            habit.iconSymbol = effectiveIconSymbol
            habit.commitmentDurationDays = effectiveCommitmentDays
        }

        dayStartHour = Int(active.dayStartHour)
        selectedThemeHex = habit.colorHex

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
                themeHex: habit.colorHex,
                advancedWidgetsEnabled: PremiumGate().canAccess(.advancedWidgets)
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

    var premiumCardTitle: String {
        switch premiumAccessState {
        case .trial:
            return L10n.text("settings.premium.card.title.trial")
        case .free:
            return L10n.text("settings.premium.card.title.free")
        case .premium:
            return L10n.text("settings.premium.card.title.active")
        }
    }

    var premiumCardSubtitle: String {
        switch premiumAccessState {
        case .trial:
            return L10n.text("settings.premium.card.subtitle.trial")
        case .free:
            return L10n.text("settings.premium.card.subtitle.free")
        case .premium:
            return L10n.text("settings.premium.card.subtitle.active")
        }
    }

    var premiumCardFootnote: String? {
        let gate = PremiumGate()

        switch premiumAccessState {
        case .trial:
            return gate.daysRemainingText()
        case .premium:
            return L10n.text("premium.state.active")
        case .free:
            return L10n.text("settings.premium.offer")
        }
    }

    var premiumButtonTitle: String {
        switch premiumAccessState {
        case .premium:
            return L10n.text("settings.manage_premium")
        case .trial, .free:
            return L10n.text("settings.open_paywall")
        }
    }

    var iCloudInfoMessage: String {
        switch iCloudStatus {
        case L10n.text("settings.status.icloud.active"):
            return L10n.text("settings.icloud.info.active")
        case L10n.text("settings.status.icloud.unavailable"):
            return L10n.text("settings.icloud.info.unavailable")
        default:
            return L10n.text("settings.icloud.info.not_configured")
        }
    }

    func refreshPremiumState(storeKitState: PremiumEntitlementState = .unknown) {
        premiumAccessState = PremiumGate(storeKitEntitlementState: storeKitState).accessState()
        clampSelectedThemeIfNeeded(
            allowPremiumThemes: PremiumGate(storeKitEntitlementState: storeKitState).canAccess(.customization)
        )
    }

    func loadArchivedRoutines(allowPremiumIcons: Bool? = nil) {
        let repository = HabitRepository(context: context)
        let canAccessPremiumIcons: Bool = allowPremiumIcons ?? (premiumAccessState != .free)
        archivedRoutines = repository.fetchArchivedHabits().map { entity in
            let habit = entity.toDomain()
            let iconSymbol = HabitIcon.effectiveSymbol(
                for: habit.iconSymbol,
                canAccessPremiumIcons: canAccessPremiumIcons
            )
            let completions = repository.fetchCompletions(habitId: habit.id)
            let bestStreak = streakEngine.bestStreak(habit: habit, completions: completions)
            let endDate = repository.latestCycleEndDate(habitId: habit.id)
                ?? completions.map(\.timestamp).max()
                ?? habit.startDate

            let rangeFormat = L10n.text("settings.archives.date_range")
            let periodText = String.localizedStringWithFormat(
                rangeFormat,
                formattedDate(habit.startDate),
                formattedDate(endDate)
            )

            let recordFormat = L10n.text("settings.archives.record")
            let recordText = String.localizedStringWithFormat(recordFormat, L10n.streakDays(bestStreak))

            return ArchivedRoutineSummary(
                id: habit.id,
                name: habit.name,
                iconSymbol: iconSymbol,
                colorHex: habit.colorHex,
                periodText: periodText,
                detailsText: "\(recordText) • \(completionCountText(completions.count))"
            )
        }
    }

    func loadUpcomingRoutines(allowPremiumIcons: Bool? = nil) {
        let repository = HabitRepository(context: context)
        let canAccessPremiumIcons: Bool = allowPremiumIcons ?? (premiumAccessState != .free)
        upcomingRoutines = repository.fetchUpcomingHabits().map { entity in
            let habit = entity.toDomain()
            let iconSymbol = HabitIcon.effectiveSymbol(
                for: habit.iconSymbol,
                canAccessPremiumIcons: canAccessPremiumIcons
            )

            return UpcomingRoutineSummary(
                id: habit.id,
                name: habit.name,
                iconSymbol: iconSymbol,
                colorHex: habit.colorHex,
                remindersText: String.localizedStringWithFormat(
                    L10n.text("onboarding.reminders.row"),
                    reminderSummary(for: habit.reminderTimes)
                ),
                dayStartText: String.localizedStringWithFormat(
                    L10n.text("onboarding.day_start.row"),
                    L10n.dayHourLabel(habit.dayStartHour)
                )
            )
        }
    }

    func activateUpcomingRoutine(id: UUID) async -> Bool {
        let repository = HabitRepository(context: context)
        guard let activated = repository.activateUpcomingHabit(id: id) else {
            return false
        }

        let habit = activated.toDomain()
        activeHabitEntity = activated
        let canAccessPremiumIcons = premiumAccessState != .free
        let iconSymbol = HabitIcon.effectiveSymbol(
            for: habit.iconSymbol,
            canAccessPremiumIcons: canAccessPremiumIcons
        )

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
                iconSymbol: iconSymbol,
                currentStreak: streak,
                doneToday: doneToday,
                themeHex: habit.colorHex,
                advancedWidgetsEnabled: PremiumGate().canAccess(.advancedWidgets)
            )
        )

        load()
        return true
    }

    private func clampSelectedThemeIfNeeded(allowPremiumThemes: Bool) {
        let normalized = Theme.effectiveThemeHex(
            for: selectedThemeHex,
            canAccessPremiumThemes: allowPremiumThemes
        )
        guard normalized != selectedThemeHex else { return }
        selectedThemeHex = normalized
    }

    private func refreshICloudStatus() {
        #if targetEnvironment(simulator)
        iCloudStatus = L10n.text("settings.status.icloud.unavailable")
        return
        #endif

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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: date)
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

    private func reminderSummary(for reminderTimes: [ReminderTime]) -> String {
        switch reminderTimes.count {
        case 0:
            return L10n.text("onboarding.reminders.summary.none")
        case 1:
            return L10n.text("onboarding.reminders.summary.one")
        default:
            let format = L10n.text("onboarding.reminders.summary.many")
            return String.localizedStringWithFormat(format, reminderTimes.count)
        }
    }
}
