import CoreData

final class HabitRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchActiveHabit() -> HabitEntity? {
        let request = HabitEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 1
        guard let activeHabit = (try? context.fetch(request))?.first else {
            return nil
        }

        let normalizedIcon = HabitIcon.normalize(activeHabit.icon)
        if activeHabit.icon != normalizedIcon {
            activeHabit.icon = normalizedIcon
            PersistenceController.shared.save(context: context)
        }

        return activeHabit
    }

    func activeHabitCount() -> Int {
        let request = HabitEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        return (try? context.count(for: request)) ?? 0
    }

    func fetchArchivedHabits() -> [HabitEntity] {
        let request = HabitEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    @discardableResult
    func createHabit(name: String,
                     iconSymbol: String,
                     colorHex: String,
                     dayStartHour: Int,
                     reminderTimes: [ReminderTime]) -> HabitEntity {
        deactivateAllHabits()

        let entity = HabitEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.icon = HabitIcon.normalize(iconSymbol)
        entity.colorHex = colorHex
        entity.startDate = Date()
        entity.dayStartHour = Int16(dayStartHour)
        entity.reminderTimes = ReminderTimesCodec.encode(Array(reminderTimes.prefix(2)))
        entity.isActive = true

        PersistenceController.shared.save(context: context)
        return entity
    }

    func updateHabit(_ habit: HabitEntity,
                     name: String? = nil,
                     iconSymbol: String? = nil,
                     colorHex: String? = nil,
                     dayStartHour: Int? = nil,
                     reminderTimes: [ReminderTime]? = nil) {
        if let name {
            habit.name = name
        }
        if let iconSymbol {
            habit.icon = HabitIcon.normalize(iconSymbol)
        }
        if let colorHex {
            habit.colorHex = colorHex
        }
        if let dayStartHour {
            habit.dayStartHour = Int16(dayStartHour)
        }
        if let reminderTimes {
            habit.reminderTimes = ReminderTimesCodec.encode(Array(reminderTimes.prefix(2)))
        }

        PersistenceController.shared.save(context: context)
    }

    @discardableResult
    func toggleCompletion(for habit: HabitEntity, now: Date = Date()) -> Bool {
        let boundary = DayBoundary(startHour: Int(habit.dayStartHour))
        let dayKey = boundary.dayKey(for: now)

        if let existing = fetchCompletion(habitId: habit.id, dayKey: dayKey) {
            context.delete(existing)
            PersistenceController.shared.save(context: context)
            return false
        }

        let completion = CompletionEntity(context: context)
        completion.id = UUID()
        completion.habitId = habit.id
        completion.dayKey = dayKey
        completion.timestamp = now
        PersistenceController.shared.save(context: context)
        return true
    }

    func fetchCompletions(habitId: UUID) -> [Completion] {
        let request = CompletionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "habitId == %@", habitId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "dayKey", ascending: true)]
        return ((try? context.fetch(request)) ?? []).map { $0.toDomain() }
    }

    func fetchCompletion(habitId: UUID, dayKey: Date) -> CompletionEntity? {
        let request = CompletionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "habitId == %@ AND dayKey == %@", habitId as CVarArg, dayKey as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    @discardableResult
    func archiveActiveHabit(now: Date = Date(), status: String = "archived") -> HabitEntity? {
        guard let activeHabit = fetchActiveHabit() else { return nil }

        activeHabit.isActive = false

        let cycle = CycleEntity(context: context)
        cycle.id = UUID()
        cycle.habitId = activeHabit.id
        cycle.cycleStart = activeHabit.startDate
        cycle.cycleEnd = now
        cycle.status = status

        PersistenceController.shared.save(context: context)
        return activeHabit
    }

    func latestCycleEndDate(habitId: UUID) -> Date? {
        let request = CycleEntity.fetchRequest()
        request.predicate = NSPredicate(format: "habitId == %@", habitId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "cycleEnd", ascending: false)]
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first?.cycleEnd
    }

    private func deactivateAllHabits() {
        let request = HabitEntity.fetchRequest()
        let allHabits = (try? context.fetch(request)) ?? []
        allHabits.forEach { $0.isActive = false }
        PersistenceController.shared.save(context: context)
    }
}
