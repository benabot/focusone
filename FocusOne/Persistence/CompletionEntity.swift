import CoreData

@objc(CompletionEntity)
public class CompletionEntity: NSManagedObject {}

extension CompletionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CompletionEntity> {
        NSFetchRequest<CompletionEntity>(entityName: "CompletionEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var habitId: UUID
    @NSManaged public var dayKey: Date
    @NSManaged public var timestamp: Date
}

extension CompletionEntity {
    func toDomain() -> Completion {
        Completion(id: id, habitId: habitId, dayKey: dayKey, timestamp: timestamp)
    }
}
