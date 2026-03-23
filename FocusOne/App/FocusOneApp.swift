import SwiftUI

@main
struct FocusOneApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var storeKit = StoreKitService()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(storeKit)
                .tint(Theme.accent)
                .task {
                    await storeKit.updateEntitlementState()
                    await storeKit.loadProducts()
                }
        }
    }
}
