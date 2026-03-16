import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

private enum WidgetIconSymbol {
    static let defaultSymbol = "sparkles"
    private static let supportedSymbols: Set<String> = [
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
        return supportedSymbols.contains(rawValue) ? rawValue : defaultSymbol
    }
}

struct WidgetDataSnapshot: Codable {
    var habitName: String
    var iconSymbol: String
    var currentStreak: Int
    var doneToday: Bool
    var themeHex: String

    private enum CodingKeys: String, CodingKey {
        case habitName
        case icon
        case iconSymbol
        case streak
        case currentStreak
        case doneToday
        case themeHex
    }

    init(
        habitName: String,
        iconSymbol: String,
        currentStreak: Int,
        doneToday: Bool,
        themeHex: String
    ) {
        self.habitName = habitName
        self.iconSymbol = WidgetIconSymbol.normalize(iconSymbol)
        self.currentStreak = currentStreak
        self.doneToday = doneToday
        self.themeHex = themeHex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habitName = try container.decode(String.self, forKey: .habitName)
        let decodedSymbol = try container.decodeIfPresent(String.self, forKey: .iconSymbol)
            ?? container.decodeIfPresent(String.self, forKey: .icon)
            ?? WidgetIconSymbol.defaultSymbol
        iconSymbol = WidgetIconSymbol.normalize(decodedSymbol)
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak)
            ?? container.decodeIfPresent(Int.self, forKey: .streak)
            ?? 0
        doneToday = try container.decode(Bool.self, forKey: .doneToday)
        themeHex = try container.decodeIfPresent(String.self, forKey: .themeHex) ?? "34C9A5"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(habitName, forKey: .habitName)
        try container.encode(iconSymbol, forKey: .iconSymbol)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(doneToday, forKey: .doneToday)
        try container.encode(themeHex, forKey: .themeHex)
    }
}

final class AppGroupStorage {
    static let shared = AppGroupStorage()
    private let key = "focusone.widget.snapshot"
    private let defaults: UserDefaults

    init(suiteName: String = AppConfig.appGroupID) {
        if let groupDefaults = UserDefaults(suiteName: suiteName) {
            defaults = groupDefaults
        } else {
            // Fallback keeps debug runs working when the App Group capability is disabled.
            defaults = .standard
        }
    }

    func saveWidgetSnapshot(_ snapshot: WidgetDataSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    func loadWidgetSnapshot() -> WidgetDataSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetDataSnapshot.self, from: data)
    }

    func clearWidgetSnapshot() {
        defaults.removeObject(forKey: key)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

// Backward-compatibility names used by earlier code.
typealias WidgetSnapshot = WidgetDataSnapshot

final class WidgetDataStore {
    static let shared = WidgetDataStore()

    private init() {}

    func save(_ snapshot: WidgetDataSnapshot) {
        AppGroupStorage.shared.saveWidgetSnapshot(snapshot)
    }

    func load() -> WidgetDataSnapshot? {
        AppGroupStorage.shared.loadWidgetSnapshot()
    }

    func clear() {
        AppGroupStorage.shared.clearWidgetSnapshot()
    }
}
