import Foundation

enum AppConfig {
    static let bundleID = "fr.beabot"
    static let cloudKitContainerIdentifier = "iCloud.fr.beabot"
    static let appGroupID = "group.fr.beabot"
}

enum AppStorageKeys {
    static let hasOnboarded = "app.hasOnboarded"
    static let notificationsEnabled = "settings.notificationsEnabled"
    static let isPremium = "premium.isEnabled"
    static let premiumTrialStartedAt = "premium.trial.startedAt"
    static let premiumPromptMidShownDay = "premium.prompt.mid.shownDay"
    static let premiumPromptEndingShownDay = "premium.prompt.ending.shownDay"
    static let premiumPromptExpiredShown = "premium.prompt.expired.shown"
}
