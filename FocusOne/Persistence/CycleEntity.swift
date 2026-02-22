import CoreData

@objc(CycleEntity)
public class CycleEntity: NSManagedObject {}

extension CycleEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CycleEntity> {
        NSFetchRequest<CycleEntity>(entityName: "CycleEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var habitId: UUID
    @NSManaged public var cycleStart: Date
    @NSManaged public var cycleEnd: Date?
    @NSManaged public var status: String
}

extension CycleEntity {
    func toDomain() -> Cycle {
        Cycle(id: id, habitId: habitId, cycleStart: cycleStart, cycleEnd: cycleEnd, status: status)
    }
}
