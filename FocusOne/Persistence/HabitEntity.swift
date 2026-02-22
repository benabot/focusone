import CoreData

@objc(HabitEntity)
public class HabitEntity: NSManagedObject {}

extension HabitEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitEntity> {
        NSFetchRequest<HabitEntity>(entityName: "HabitEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var icon: String
    @NSManaged public var colorHex: String
    @NSManaged public var startDate: Date
    @NSManaged public var dayStartHour: Int16
    @NSManaged public var reminderTimes: String?
    @NSManaged public var isActive: Bool
}

extension HabitEntity {
    func toDomain() -> Habit {
        Habit(
            id: id,
            name: name,
            iconSymbol: HabitIcon.normalize(icon),
            colorHex: colorHex,
            startDate: startDate,
            dayStartHour: Int(dayStartHour),
            reminderTimes: ReminderTimesCodec.decode(reminderTimes),
            isActive: isActive
        )
    }
}
