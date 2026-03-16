import Foundation

enum PremiumFeature: String, Identifiable {
    case fullHistory
    case archives
    case nextRoutine
    case advancedWidgets

    var id: String { rawValue }

    var gateTitleKey: String {
        switch self {
        case .fullHistory:
            return "premium.gate.history.title"
        case .archives:
            return "premium.gate.archive.title"
        case .nextRoutine:
            return "premium.gate.next.title"
        case .advancedWidgets:
            return "premium.gate.widgets.title"
        }
    }

    var gateMessageKey: String {
        switch self {
        case .fullHistory:
            return "premium.gate.history.message"
        case .archives:
            return "premium.gate.archive.message"
        case .nextRoutine:
            return "premium.gate.next.message"
        case .advancedWidgets:
            return "premium.gate.widgets.message"
        }
    }
}

enum PremiumAccessState: Equatable {
    case premium
    case trial(daysRemaining: Int, endExclusive: Date)
    case free
}

enum PremiumPromptKind: String, Identifiable {
    case midTrial
    case endingSoon
    case expired

    var id: String { rawValue }
}

struct PremiumGate {
    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    var hasPaidEntitlement: Bool {
        defaults.bool(forKey: AppStorageKeys.isPremium)
    }

    mutating func startTrialIfNeeded(now: Date = .now) {
        guard defaults.object(forKey: AppStorageKeys.premiumTrialStartedAt) == nil else { return }
        let start = calendar.startOfDay(for: now).timeIntervalSince1970
        defaults.set(start, forKey: AppStorageKeys.premiumTrialStartedAt)
    }

    func accessState(now: Date = .now) -> PremiumAccessState {
        if hasPaidEntitlement {
            return .premium
        }

        guard let start = trialStartDate else {
            return .free
        }

        let today = calendar.startOfDay(for: now)
        guard let endExclusive = calendar.date(byAdding: .day, value: 10, to: start) else {
            return .free
        }

        guard today < endExclusive else {
            return .free
        }

        let daysRemaining = max(1, calendar.dateComponents([.day], from: today, to: endExclusive).day ?? 0)
        return .trial(daysRemaining: daysRemaining, endExclusive: endExclusive)
    }

    func canAccess(_ feature: PremiumFeature, now: Date = .now) -> Bool {
        _ = feature

        switch accessState(now: now) {
        case .premium, .trial:
            return true
        case .free:
            return false
        }
    }

    func pendingLifecyclePrompt(now: Date = .now) -> PremiumPromptKind? {
        guard !hasPaidEntitlement else { return nil }
        guard let trialStartDate else { return nil }

        let today = calendar.startOfDay(for: now)
        guard let endExclusive = calendar.date(byAdding: .day, value: 10, to: trialStartDate) else {
            return nil
        }

        if today >= endExclusive {
            return defaults.bool(forKey: AppStorageKeys.premiumPromptExpiredShown) ? nil : .expired
        }

        let daysRemaining = calendar.dateComponents([.day], from: today, to: endExclusive).day ?? 0
        let dayStamp = self.dayStamp(today)

        if daysRemaining == 4 {
            let shownDay = defaults.string(forKey: AppStorageKeys.premiumPromptMidShownDay)
            return shownDay == dayStamp ? nil : .midTrial
        }

        if daysRemaining == 1 {
            let shownDay = defaults.string(forKey: AppStorageKeys.premiumPromptEndingShownDay)
            return shownDay == dayStamp ? nil : .endingSoon
        }

        return nil
    }

    mutating func markPromptShown(_ prompt: PremiumPromptKind, now: Date = .now) {
        let stamp = dayStamp(calendar.startOfDay(for: now))

        switch prompt {
        case .midTrial:
            defaults.set(stamp, forKey: AppStorageKeys.premiumPromptMidShownDay)
        case .endingSoon:
            defaults.set(stamp, forKey: AppStorageKeys.premiumPromptEndingShownDay)
        case .expired:
            defaults.set(true, forKey: AppStorageKeys.premiumPromptExpiredShown)
        }
    }

    func daysRemainingText(now: Date = .now) -> String? {
        switch accessState(now: now) {
        case .trial(let daysRemaining, _):
            if daysRemaining == 1 {
                return L10n.text("premium.trial.remaining.one")
            }

            let format = L10n.text("premium.trial.remaining.other")
            return String.localizedStringWithFormat(format, daysRemaining)
        case .premium, .free:
            return nil
        }
    }

    func endDateText(now: Date = .now) -> String? {
        switch accessState(now: now) {
        case .trial(_, let endExclusive):
            guard let lastDay = calendar.date(byAdding: .day, value: -1, to: endExclusive) else {
                return nil
            }
            let format = L10n.text("premium.trial.ends_on")
            return String.localizedStringWithFormat(format, formattedDate(lastDay))
        case .premium, .free:
            return nil
        }
    }

    func trialEndDateString(now: Date = .now) -> String? {
        switch accessState(now: now) {
        case .trial(_, let endExclusive):
            guard let lastDay = calendar.date(byAdding: .day, value: -1, to: endExclusive) else {
                return nil
            }
            return formattedDate(lastDay)
        case .premium, .free:
            return nil
        }
    }

    private var trialStartDate: Date? {
        guard defaults.object(forKey: AppStorageKeys.premiumTrialStartedAt) != nil else { return nil }
        let timestamp = defaults.double(forKey: AppStorageKeys.premiumTrialStartedAt)
        return calendar.startOfDay(for: Date(timeIntervalSince1970: timestamp))
    }

    private func dayStamp(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
