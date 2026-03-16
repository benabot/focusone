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
}
