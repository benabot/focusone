import Foundation
import UserNotifications

final class NotificationsService {
    static let shared = NotificationsService()

    private let center = UNUserNotificationCenter.current()
    private let reminderIdentifiers = ["focusone.reminder.0", "focusone.reminder.1"]

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func scheduleDailyReminders(for habit: Habit) async {
        await clearReminders()

        let sortedTimes = habit.reminderTimes.sorted().prefix(2)
        for (index, time) in sortedTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = habit.name
            content.body = L10n.text("notifications.body")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: time.toDateComponents(), repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderIdentifiers[index],
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                continue
            }
        }
    }

    func clearReminders() async {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
    }
}
