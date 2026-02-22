import SwiftUI

@main
struct FocusOneApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tint(Theme.accent)
        }
    }
}
