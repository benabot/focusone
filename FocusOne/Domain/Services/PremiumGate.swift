import Foundation

struct PremiumGate {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isPremium: Bool {
        defaults.bool(forKey: AppStorageKeys.isPremium)
    }

    func canCreateAdditionalHabit(existingActiveHabitCount: Int) -> Bool {
        isPremium || existingActiveHabitCount == 0
    }

    func canUseCycles() -> Bool {
        isPremium
    }
}
