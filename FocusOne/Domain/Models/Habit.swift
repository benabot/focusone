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

    var isActive: Bool {
        lifecycleState == .active
    }

    var isUpcoming: Bool {
        lifecycleState == .upcoming
    }
}

enum HabitIcon {
    static let defaultSymbol = "sparkles"
    static let availableSymbols = [
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

    static func normalize(_ rawValue: String?) -> String {
        guard let rawValue, !rawValue.isEmpty else { return defaultSymbol }

        if rawValue == "profile" {
            return "person.crop.circle.fill"
        }

        guard availableSymbols.contains(rawValue) else { return defaultSymbol }
        return rawValue
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
