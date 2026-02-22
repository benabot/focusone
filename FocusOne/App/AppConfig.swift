import Foundation

enum AppConfig {
    static let bundleID = "com.benoit.focusone"
    static let cloudKitContainerIdentifier = "iCloud.com.benoit.focusone"
    static let appGroupID = "group.com.benoit.focusone"
}

enum AppStorageKeys {
    static let hasOnboarded = "app.hasOnboarded"
    static let notificationsEnabled = "settings.notificationsEnabled"
    static let isPremium = "premium.isEnabled"
}
