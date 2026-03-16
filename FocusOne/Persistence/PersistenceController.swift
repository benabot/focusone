import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private var hasAttemptedStoreReset = false
    private var hasAttemptedInMemoryFallback = false

    init(inMemory: Bool = false) {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let usesCloudKitContainer = !inMemory && !isPreview && RuntimeCapabilities.cloudKitEnabled

        if usesCloudKitContainer {
            container = NSPersistentCloudKitContainer(name: "Model")
        } else {
            container = NSPersistentContainer(name: "Model")
        }

        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            if usesCloudKitContainer {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: AppConfig.cloudKitContainerIdentifier
                )
            }
        }

        loadPersistentStores(inMemory: inMemory, isPreview: isPreview)

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save(context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            assertionFailure("Core Data save error: \(error)")
        }
    }

    private func loadPersistentStores(inMemory: Bool, isPreview: Bool) {
        container.loadPersistentStores { [weak self] _, error in
            guard let self else { return }
            guard let error else { return }

            if !inMemory && !isPreview && self.shouldResetStore(after: error) && !self.hasAttemptedStoreReset {
                self.hasAttemptedStoreReset = true
                self.recoverPersistentStore(from: error, inMemory: inMemory, isPreview: isPreview)
                return
            }

            if !inMemory && RuntimeCapabilities.usesInMemoryFallback && !self.hasAttemptedInMemoryFallback {
                self.hasAttemptedInMemoryFallback = true
                self.fallbackToInMemoryStore(after: error, inMemory: inMemory, isPreview: isPreview)
                return
            }

            NSLog("FocusOne persistent store load error: %@", error.localizedDescription)
        }
    }

    private func recoverPersistentStore(from error: Error, inMemory: Bool, isPreview: Bool) {
        guard let description = container.persistentStoreDescriptions.first,
              let storeURL = description.url else {
            NSLog("FocusOne failed to recover persistent store after error: %@", error.localizedDescription)
            return
        }

        do {
            try destroyStoreFiles(at: storeURL, type: description.type)
            NSLog("FocusOne recreated incompatible persistent store at %@", storeURL.path)
            loadPersistentStores(inMemory: inMemory, isPreview: isPreview)
        } catch {
            if RuntimeCapabilities.usesInMemoryFallback {
                fallbackToInMemoryStore(after: error, inMemory: inMemory, isPreview: isPreview)
            } else {
                NSLog("FocusOne failed to destroy persistent store %@: %@", storeURL.path, error.localizedDescription)
            }
        }
    }

    private func fallbackToInMemoryStore(after error: Error, inMemory: Bool, isPreview: Bool) {
        guard let description = container.persistentStoreDescriptions.first else {
            NSLog("FocusOne in-memory fallback unavailable after store error: %@", error.localizedDescription)
            return
        }

        NSLog("FocusOne falling back to in-memory store after load error: %@", error.localizedDescription)
        description.url = URL(fileURLWithPath: "/dev/null")
        description.cloudKitContainerOptions = nil

        loadPersistentStores(inMemory: true, isPreview: isPreview)
    }

    private func destroyStoreFiles(at storeURL: URL, type: String) throws {
        try container.persistentStoreCoordinator.destroyPersistentStore(
            at: storeURL,
            type: NSPersistentStore.StoreType(rawValue: type),
            options: nil
        )

        let fileManager = FileManager.default
        let sidecarURLs = [
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for sidecarURL in sidecarURLs where fileManager.fileExists(atPath: sidecarURL.path) {
            try fileManager.removeItem(at: sidecarURL)
        }
    }

    private func shouldResetStore(after error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSCocoaErrorDomain else { return false }

        return RuntimeCapabilities.resettableStoreErrors.contains(nsError.code)
    }
}

private enum RuntimeCapabilities {
    // Debug builds run without CloudKit capability so simulator and Personal Team
    // launches don't trap during store setup.
    static let cloudKitEnabled: Bool = {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }()

    static let usesInMemoryFallback: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    static let resettableStoreErrors: Set<Int> = [
        NSMigrationError,
        NSMigrationMissingSourceModelError,
        NSMigrationMissingMappingModelError,
        NSMigrationManagerSourceStoreError,
        NSMigrationManagerDestinationStoreError,
        NSPersistentStoreIncompatibleVersionHashError,
        NSPersistentStoreIncompatibleSchemaError,
        NSPersistentStoreInvalidTypeError
    ]
}
