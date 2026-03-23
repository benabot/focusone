import Foundation

enum HabitLifecycleState: String, Codable, Equatable {
    case active
    case upcoming
    case archived

    static func resolve(rawValue: String?, isActive: Bool) -> HabitLifecycleState {
        if isActive {
            return .active
        }

        guard let rawValue, let state = HabitLifecycleState(rawValue: rawValue) else {
            return .archived
        }
        return state
    }
}

struct Habit: Identifiable, Equatable {
    let id: UUID
    var name: String
    var iconSymbol: String
    var colorHex: String
    var startDate: Date
    var dayStartHour: Int
    var reminderTimes: [ReminderTime]
    var lifecycleState: HabitLifecycleState
    var commitmentDurationDays: Int?

    var isActive: Bool {
        lifecycleState == .active
    }

    var isUpcoming: Bool {
        lifecycleState == .upcoming
    }

    var commitmentEndDate: Date? {
        guard let commitmentDurationDays else { return nil }
        return Calendar.current.date(byAdding: .day, value: commitmentDurationDays, to: startDate)
    }

    var hasCommitment: Bool {
        commitmentDurationDays != nil
    }
}

enum HabitIcon {
    static let defaultSymbol = "sparkles"
    static let freeSymbols = [
        "person.crop.circle.fill",
        "timer",
        "sun.max.fill",
        "moon.stars.fill",
        "checkmark.seal.fill",
        "sparkles",
        "drop.fill",
        "figure.walk",
        "book.fill",
        "heart.fill"
    ]

    static let premiumSymbols = [
        "flame.fill",
        "leaf.fill",
        "bolt.fill",
        "star.circle.fill",
        "wand.and.stars",
        "target",
        "chart.line.uptrend.xyaxis",
        "medal.fill"
    ]

    static var availableSymbols: [String] {
        freeSymbols + premiumSymbols
    }

    static var allSymbols: [String] {
        availableSymbols
    }

    static var freeCount: Int {
        freeSymbols.count
    }

    static func normalize(_ rawValue: String?) -> String {
        guard let rawValue, !rawValue.isEmpty else { return defaultSymbol }

        if rawValue == "profile" {
            return "person.crop.circle.fill"
        }

        guard availableSymbols.contains(rawValue) else { return defaultSymbol }
        return rawValue
    }

    static func isPremiumSymbol(_ symbol: String) -> Bool {
        premiumSymbols.contains(symbol)
    }

    static func accessibleSymbols(canAccessPremiumIcons: Bool) -> [String] {
        canAccessPremiumIcons ? availableSymbols : freeSymbols
    }

    static func effectiveSymbol(for symbol: String, canAccessPremiumIcons: Bool) -> String {
        guard canAccessPremiumIcons || !isPremiumSymbol(symbol) else {
            return defaultSymbol
        }
        return normalize(symbol)
    }
}

enum CommitmentDurationOption: Int, CaseIterable, Identifiable {
    case none = 0
    case seven = 7
    case ten = 10
    case fifteen = 15
    case thirty = 30

    var id: Int { rawValue }

    var isPremium: Bool {
        self != .none
    }

    var durationDays: Int? {
        self == .none ? nil : rawValue
    }

    var titleKey: String {
        switch self {
        case .none: return "commitment.duration.none"
        case .seven: return "commitment.duration.7"
        case .ten: return "commitment.duration.10"
        case .fifteen: return "commitment.duration.15"
        case .thirty: return "commitment.duration.30"
        }
    }

    static func option(for durationDays: Int?) -> CommitmentDurationOption {
        guard let durationDays else { return .none }
        return Self(rawValue: durationDays) ?? .none
    }

    static func effectiveDurationDays(for durationDays: Int?, canAccessPremiumDuration: Bool) -> Int? {
        guard canAccessPremiumDuration else { return nil }
        guard let durationDays, Self(rawValue: durationDays) != nil else { return nil }
        return durationDays
    }
}

struct ReminderTime: Codable, Hashable, Comparable {
    var hour: Int
    var minute: Int

    static func < (lhs: ReminderTime, rhs: ReminderTime) -> Bool {
        if lhs.hour != rhs.hour {
            return lhs.hour < rhs.hour
        }
        return lhs.minute < rhs.minute
    }

    var clockLabel: String {
        String(format: "%02d:%02d", hour, minute)
    }

    static func from(date: Date, calendar: Calendar = .current) -> ReminderTime {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return ReminderTime(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
    }

    func toDate(on baseDate: Date = Date(), calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    func toDateComponents() -> DateComponents {
        DateComponents(hour: hour, minute: minute)
    }
}
