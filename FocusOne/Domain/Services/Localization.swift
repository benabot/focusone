import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func streakDays(_ count: Int) -> String {
        let format = NSLocalizedString("streak.days", comment: "")
        return String.localizedStringWithFormat(format, count)
    }

    static func streakUnit(_ count: Int) -> String {
        count == 1
            ? NSLocalizedString("home.streak.unit.one", comment: "")
            : NSLocalizedString("home.streak.unit.other", comment: "")
    }

    static func streakInARowLabel(_ count: Int) -> String {
        if count == 1 {
            return NSLocalizedString("home.streak.row.one", comment: "")
        }
        return NSLocalizedString("home.streak.row.other", comment: "")
    }

    static func dayHourLabel(_ hour: Int) -> String {
        String(format: NSLocalizedString("time.hour.format", comment: ""), hour)
    }

    static func completionPercent(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        let format = NSLocalizedString("stats.percent.format", comment: "")
        return String(format: format, percent)
    }
}
