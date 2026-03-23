import Foundation

enum AppConfig {
    static let appBundleID = "fr.beabot.FocusOne"
    static let widgetBundleID = "fr.beabot.FocusOne.widget"
    static let appGroupID = "group.fr.beabot.FocusOne"
    static let cloudKitContainerIdentifier = "iCloud.fr.beabot.FocusOne"
}

enum PremiumConfig {
    static let yearlyProductID = "com.benoit.focusone.premium.yearly"
    static let lifetimeProductID = "com.benoit.focusone.lifetime"
    static let productIDs = [yearlyProductID, lifetimeProductID]

    static let freeThemeCount = 4
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
