import CoreData
import Foundation

enum PreviewSupport {
    static let persistenceController = PersistenceController(inMemory: true)
    private static var hasSeeded = false

    static var context: NSManagedObjectContext {
        seedIfNeeded()
        return persistenceController.container.viewContext
    }

    private static func seedIfNeeded() {
        guard !hasSeeded else { return }
        hasSeeded = true

        let repository = HabitRepository(context: persistenceController.container.viewContext)
        guard repository.fetchActiveHabit() == nil else { return }

        let habit = repository.createHabit(
            name: "Read 10 min",
            iconSymbol: "person.crop.circle.fill",
            colorHex: Theme.presets[0].primaryHex,
            dayStartHour: 4,
            reminderTimes: [ReminderTime(hour: 9, minute: 0), ReminderTime(hour: 21, minute: 0)]
        )

        let calendar = Calendar.current
        let offsets = [0, 1, 2, 4, 6, 9, 12, 20]
        for offset in offsets {
            if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                _ = repository.toggleCompletion(for: habit, now: date)
            }
        }
    }
}
