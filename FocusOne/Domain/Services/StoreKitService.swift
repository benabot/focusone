import Foundation
import StoreKit

// MARK: - Product identifiers

enum StoreProduct: String, CaseIterable {
    case yearly   = "com.benoit.focusone.premium.yearly"
    case lifetime = "com.benoit.focusone.lifetime"
}

// MARK: - Purchase result

enum PurchaseResult {
    case success
    case cancelled
    case pending
    case failed(Error)
}

// MARK: - StoreKitService

final class StoreKitService: ObservableObject {

    @Published private(set) var products: [Product] = []
    @Published private(set) var entitlementState: PremiumEntitlementState = .unknown

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let ids = StoreProduct.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            let sorted = fetched.sorted { a, b in
                let order = [StoreProduct.yearly.rawValue, StoreProduct.lifetime.rawValue]
                return (order.firstIndex(of: a.id) ?? 99) < (order.firstIndex(of: b.id) ?? 99)
            }
            await MainActor.run { products = sorted }
        } catch {
            print("[StoreKit] loadProducts error: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> PurchaseResult {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateEntitlementState()
                await transaction.finish()
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .cancelled
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateEntitlementState()
        } catch {
            print("[StoreKit] restorePurchases error: \(error)")
        }
    }


    // MARK: - Entitlement refresh

    func updateEntitlementState() async {
        var hasYearly = false
        var hasLifetime = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.productID == StoreProduct.yearly.rawValue,
               transaction.revocationDate == nil {
                hasYearly = true
            }
            if transaction.productID == StoreProduct.lifetime.rawValue,
               transaction.revocationDate == nil {
                hasLifetime = true
            }
        }

        let newState: PremiumEntitlementState = (hasYearly || hasLifetime) ? .active : .none
        await MainActor.run { entitlementState = newState }
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await self.updateEntitlementState()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    // MARK: - Convenience

    var yearlyProduct: Product? {
        products.first { $0.id == StoreProduct.yearly.rawValue }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == StoreProduct.lifetime.rawValue }
    }
}

// MARK: - PremiumEntitlementState

enum PremiumEntitlementState: Equatable {
    case unknown   // pas encore vérifié
    case active    // abonnement annuel ou lifetime actif
    case none      // aucun entitlement
}
