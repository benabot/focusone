import Foundation
import OSLog
import StoreKit

enum PremiumFeature: String, Identifiable {
    case advancedStats
    case fullHistory
    case archives
    case nextRoutine
    case advancedWidgets
    case customization

    var id: String { rawValue }

    var gateTitleKey: String {
        switch self {
        case .advancedStats:
            return "premium.gate.stats.title"
        case .fullHistory:
            return "premium.gate.history.title"
        case .archives:
            return "premium.gate.archive.title"
        case .nextRoutine:
            return "premium.gate.next.title"
        case .advancedWidgets:
            return "premium.gate.widgets.title"
        case .customization:
            return "premium.gate.customization.title"
        }
    }

    var gateMessageKey: String {
        switch self {
        case .advancedStats:
            return "premium.gate.stats.message"
        case .fullHistory:
            return "premium.gate.history.message"
        case .archives:
            return "premium.gate.archive.message"
        case .nextRoutine:
            return "premium.gate.next.message"
        case .advancedWidgets:
            return "premium.gate.widgets.message"
        case .customization:
            return "premium.gate.customization.message"
        }
    }
}

enum PremiumAccessState: Equatable {
    case premium
    case trial(daysRemaining: Int, endExclusive: Date)
    case free
}

enum PremiumPromptKind: String, Identifiable {
    case midTrial
    case endingSoon
    case expired

    var id: String { rawValue }
}

enum PremiumEntitlementState: Equatable {
    case unknown
    case active
    case none
}

enum StoreProduct: CaseIterable {
    case yearly
    case lifetime

    var id: String {
        switch self {
        case .yearly:
            return PremiumConfig.yearlyProductID
        case .lifetime:
            return PremiumConfig.lifetimeProductID
        }
    }
}

enum PurchaseResult {
    case success
    case cancelled
    case pending
    case failed(Error)
}

final class StoreKitService: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var entitlementState: PremiumEntitlementState = .unknown

    private var transactionListener: Task<Void, Never>?
    private let logger = Logger(subsystem: AppConfig.appBundleID, category: "StoreKit")

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        let requestedIDs = StoreProduct.allCases.map(\.id)
        let requestedIDsText = requestedIDs.joined(separator: ", ")
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let isPreviewContext = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        logger.info(
            "StoreKit context bundle id: \(bundleID, privacy: .public), preview: \(String(isPreviewContext), privacy: .public)"
        )
        logger.info("Loading StoreKit products for ids: \(requestedIDsText)")

        do {
            let fetched = try await Product.products(for: requestedIDs)
            let sorted = fetched.sorted { lhs, rhs in
                let order = [StoreProduct.yearly.id, StoreProduct.lifetime.id]
                return (order.firstIndex(of: lhs.id) ?? order.count) < (order.firstIndex(of: rhs.id) ?? order.count)
            }
            await MainActor.run {
                products = sorted
            }

            let returnedIDs = fetched.map(\.id).joined(separator: ", ")
            logger.info("StoreKit returned \(fetched.count, privacy: .public) products: \(returnedIDs)")
            if fetched.isEmpty {
                logger.warning("StoreKit returned zero products for ids: \(requestedIDsText)")
            }
        } catch {
            await MainActor.run {
                products = []
            }
            logger.error("StoreKit product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase(_ product: Product) async -> PurchaseResult {
        do {
            logger.info("Purchase requested for \(product.id, privacy: .public)")
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateEntitlementState()
                await transaction.finish()
                logger.info("Purchase succeeded for \(product.id, privacy: .public)")
                return .success
            case .userCancelled:
                logger.info("Purchase cancelled for \(product.id, privacy: .public)")
                return .cancelled
            case .pending:
                logger.info("Purchase pending for \(product.id, privacy: .public)")
                return .pending
            @unknown default:
                return .cancelled
            }
        } catch {
            logger.error("Purchase failed for \(product.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return .failed(error)
        }
    }

    func restorePurchases() async -> Bool {
        do {
            logger.info("Restore purchases requested")
            try await AppStore.sync()
            await updateEntitlementState()
            logger.info("Restore purchases finished with entitlement state: \(String(describing: self.entitlementState), privacy: .public)")
            return entitlementState == .active
        } catch {
            logger.error("Restore purchases failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func updateEntitlementState() async {
        var hasPaidEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if [StoreProduct.yearly.id, StoreProduct.lifetime.id].contains(transaction.productID),
               transaction.revocationDate == nil {
                hasPaidEntitlement = true
                break
            }
        }

        let newState: PremiumEntitlementState = hasPaidEntitlement ? .active : .none
        await MainActor.run {
            entitlementState = newState
        }
        UserDefaults.standard.set(hasPaidEntitlement, forKey: AppStorageKeys.isPremium)
    }

    var yearlyProduct: Product? {
        products.first { $0.id == StoreProduct.yearly.id }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == StoreProduct.lifetime.id }
    }

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

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            throw error
        }
    }
}

struct PremiumGate {
    private let defaults: UserDefaults
    private let calendar: Calendar
    var storeKitEntitlementState: PremiumEntitlementState?

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        storeKitEntitlementState: PremiumEntitlementState? = nil
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.storeKitEntitlementState = storeKitEntitlementState
    }

    var hasPaidEntitlement: Bool {
        if let storeKitEntitlementState {
            if storeKitEntitlementState == .unknown {
                return defaults.bool(forKey: AppStorageKeys.isPremium)
            }
            return storeKitEntitlementState == .active
        }
        return defaults.bool(forKey: AppStorageKeys.isPremium)
    }

    mutating func startTrialIfNeeded(now: Date = .now) {
        guard defaults.object(forKey: AppStorageKeys.premiumTrialStartedAt) == nil else { return }
        let start = calendar.startOfDay(for: now).timeIntervalSince1970
        defaults.set(start, forKey: AppStorageKeys.premiumTrialStartedAt)
    }

    mutating func setHasPaidEntitlement(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: AppStorageKeys.isPremium)

        guard isEnabled else { return }
        defaults.set(false, forKey: AppStorageKeys.premiumPromptExpiredShown)
    }

    func accessState(now: Date = .now) -> PremiumAccessState {
        if hasPaidEntitlement {
            return .premium
        }

        guard let start = trialStartDate else {
            return .free
        }

        let today = calendar.startOfDay(for: now)
        guard let endExclusive = calendar.date(byAdding: .day, value: 10, to: start) else {
            return .free
        }

        guard today < endExclusive else {
            return .free
        }

        let daysRemaining = max(1, calendar.dateComponents([.day], from: today, to: endExclusive).day ?? 0)
        return .trial(daysRemaining: daysRemaining, endExclusive: endExclusive)
    }

    func canAccess(_ feature: PremiumFeature, now: Date = .now) -> Bool {
        _ = feature

        switch accessState(now: now) {
        case .premium, .trial:
            return true
        case .free:
            return false
        }
    }

    func pendingLifecyclePrompt(now: Date = .now) -> PremiumPromptKind? {
        guard !hasPaidEntitlement else { return nil }
        guard let trialStartDate else { return nil }

        let today = calendar.startOfDay(for: now)
        guard let endExclusive = calendar.date(byAdding: .day, value: 10, to: trialStartDate) else {
            return nil
        }

        if today >= endExclusive {
            return defaults.bool(forKey: AppStorageKeys.premiumPromptExpiredShown) ? nil : .expired
        }

        let daysRemaining = calendar.dateComponents([.day], from: today, to: endExclusive).day ?? 0
        let dayStamp = self.dayStamp(today)

        if daysRemaining == 4 {
            let shownDay = defaults.string(forKey: AppStorageKeys.premiumPromptMidShownDay)
            return shownDay == dayStamp ? nil : .midTrial
        }

        if daysRemaining == 1 {
            let shownDay = defaults.string(forKey: AppStorageKeys.premiumPromptEndingShownDay)
            return shownDay == dayStamp ? nil : .endingSoon
        }

        return nil
    }

    mutating func markPromptShown(_ prompt: PremiumPromptKind, now: Date = .now) {
        let stamp = dayStamp(calendar.startOfDay(for: now))

        switch prompt {
        case .midTrial:
            defaults.set(stamp, forKey: AppStorageKeys.premiumPromptMidShownDay)
        case .endingSoon:
            defaults.set(stamp, forKey: AppStorageKeys.premiumPromptEndingShownDay)
        case .expired:
            defaults.set(true, forKey: AppStorageKeys.premiumPromptExpiredShown)
        }
    }

    func daysRemainingText(now: Date = .now) -> String? {
        switch accessState(now: now) {
        case .trial(let daysRemaining, _):
            if daysRemaining == 1 {
                return L10n.text("premium.trial.remaining.one")
            }

            let format = L10n.text("premium.trial.remaining.other")
            return String.localizedStringWithFormat(format, daysRemaining)
        case .premium, .free:
            return nil
        }
    }

    func endDateText(now: Date = .now) -> String? {
        switch accessState(now: now) {
        case .trial(_, let endExclusive):
            guard let lastDay = calendar.date(byAdding: .day, value: -1, to: endExclusive) else {
                return nil
            }
            let format = L10n.text("premium.trial.ends_on")
            return String.localizedStringWithFormat(format, formattedDate(lastDay))
        case .premium, .free:
            return nil
        }
    }

    func trialEndDateString(now: Date = .now) -> String? {
        switch accessState(now: now) {
        case .trial(_, let endExclusive):
            guard let lastDay = calendar.date(byAdding: .day, value: -1, to: endExclusive) else {
                return nil
            }
            return formattedDate(lastDay)
        case .premium, .free:
            return nil
        }
    }

    private var trialStartDate: Date? {
        guard defaults.object(forKey: AppStorageKeys.premiumTrialStartedAt) != nil else { return nil }
        let timestamp = defaults.double(forKey: AppStorageKeys.premiumTrialStartedAt)
        return calendar.startOfDay(for: Date(timeIntervalSince1970: timestamp))
    }

    private func dayStamp(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter.string(from: date)
    }
}
