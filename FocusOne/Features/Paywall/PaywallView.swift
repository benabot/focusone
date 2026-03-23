import SwiftUI
import OSLog
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var hasLoadedProducts = false
    @State private var hasLoggedUnavailableFallback = false
    @State private var purchaseError: String?
    @State private var showError = false

    let highlightYearly: Bool

    private let accentHex = Theme.presets[3].primaryHex
    private let logger = Logger(subsystem: AppConfig.appBundleID, category: "Paywall")

    init(highlightYearly: Bool = false) {
        self.highlightYearly = highlightYearly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    header
                    freeModeCard
                    productSection
                    benefitsSection
                }
                .padding(Theme.spacingL)
                .padding(.bottom, 96)
            }
            .background(Theme.backgroundGradient(for: Theme.presets[3], scheme: colorScheme).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                footer
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
            .alert(L10n.text("paywall.error.title"), isPresented: $showError) {
                Button(L10n.text("common.close"), role: .cancel) {}
            } message: {
                Text(purchaseError ?? "")
            }
        }
        .task {
            logger.debug("Paywall product load started")
            await storeKit.loadProducts()
            hasLoadedProducts = true
            logger.debug("Paywall product load finished with \(storeKit.products.count, privacy: .public) products")
        }
        .onChange(of: storeKit.entitlementState) { newState in
            if newState == .active {
                AppGroupStorage.shared.updateAdvancedWidgetsAccess(
                    PremiumGate(storeKitEntitlementState: newState).canAccess(.advancedWidgets)
                )
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("paywall.badge"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: accentHex))
                .kerning(0.8)

            Text(L10n.text("paywall.title"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(L10n.text("paywall.subtitle"))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var freeModeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("paywall.free.title"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(L10n.text("paywall.note"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard)
    }

    private var productSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(L10n.text("paywall.plans.title"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))

            if !storeKit.products.isEmpty {
                productCards
            } else if hasLoadedProducts {
                unavailableProductsCard
                    .onAppear {
                        guard !hasLoggedUnavailableFallback else { return }
                        hasLoggedUnavailableFallback = true
                        logger.warning("Paywall showing unavailable-products fallback after completed load with zero products")
                    }
            } else {
                loadingProductsCard
            }
        }
    }

    private var productCards: some View {
        VStack(spacing: Theme.spacingS) {
            if let yearly = storeKit.yearlyProduct {
                YearlyProductCard(
                    product: yearly,
                    accentHex: accentHex,
                    isLoading: isPurchasing,
                    highlight: highlightYearly
                ) {
                    await buy(yearly)
                }
            }

            if let lifetime = storeKit.lifetimeProduct {
                LifetimeProductCard(
                    product: lifetime,
                    accentHex: accentHex,
                    isLoading: isPurchasing
                ) {
                    await buy(lifetime)
                }
            }
        }
    }

    private var loadingProductsCard: some View {
        HStack(spacing: Theme.spacingS) {
            ProgressView()
                .controlSize(.regular)

            Text(L10n.text("paywall.products.loading"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard)
    }

    private var unavailableProductsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("paywall.error.products.short_title"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(L10n.text("paywall.error.products.message"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard)
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(L10n.text("paywall.features.title"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .kerning(0.4)
                .padding(.leading, 4)

            benefitRow(
                symbol: "chart.bar.xaxis",
                title: L10n.text("paywall.feature.stats.title"),
                detail: L10n.text("paywall.feature.stats.detail")
            )
            benefitRow(
                symbol: "clock.arrow.circlepath",
                title: L10n.text("paywall.feature.history.title"),
                detail: L10n.text("paywall.feature.history.detail")
            )
            benefitRow(
                symbol: "rectangle.grid.2x2.fill",
                title: L10n.text("paywall.feature.widgets.title"),
                detail: L10n.text("paywall.feature.widgets.detail")
            )
            benefitRow(
                symbol: "archivebox.fill",
                title: L10n.text("paywall.feature.cycles.title"),
                detail: L10n.text("paywall.feature.cycles.detail")
            )
            benefitRow(
                symbol: "sparkles",
                title: L10n.text("paywall.feature.icons.title"),
                detail: L10n.text("paywall.feature.icons.detail")
            )
            benefitRow(
                symbol: "calendar.badge.clock",
                title: L10n.text("paywall.feature.duration.title"),
                detail: L10n.text("paywall.feature.duration.detail")
            )
            benefitRow(
                symbol: "paintpalette.fill",
                title: L10n.text("paywall.feature.customization.title"),
                detail: L10n.text("paywall.feature.customization.detail")
            )
        }
    }

    private func benefitRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: accentHex).opacity(0.16))
                    .frame(width: 42, height: 42)

                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: accentHex))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Text(detail)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(glassCard)
    }

    private var footer: some View {
        VStack(spacing: Theme.spacingXS) {
            Button(L10n.text("paywall.secondary.later")) {
                dismiss()
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
            .buttonStyle(.plain)

            Button {
                Task {
                    await restore()
                }
            } label: {
                if isRestoring {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(L10n.text("paywall.secondary.restore"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: accentHex))
                }
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, Theme.spacingS)
        .background(
            Theme.backgroundTint.opacity(colorScheme == .dark ? 0.15 : 0.94)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func buy(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = await storeKit.purchase(product)
        switch result {
        case .success:
            AppGroupStorage.shared.updateAdvancedWidgetsAccess(
                PremiumGate(storeKitEntitlementState: storeKit.entitlementState).canAccess(.advancedWidgets)
            )
            dismiss()
        case .cancelled:
            break
        case .pending:
            purchaseError = L10n.text("paywall.pending.message")
            showError = true
        case .failed(let error):
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func restore() async {
        isRestoring = true
        let restored = await storeKit.restorePurchases()
        isRestoring = false

        if restored {
            AppGroupStorage.shared.updateAdvancedWidgetsAccess(
                PremiumGate(storeKitEntitlementState: storeKit.entitlementState).canAccess(.advancedWidgets)
            )
            dismiss()
        } else {
            purchaseError = L10n.text("paywall.restore.error.message")
            showError = true
        }
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
            .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
            )
    }
}

private struct YearlyProductCard: View {
    let product: Product
    let accentHex: String
    let isLoading: Bool
    let highlight: Bool
    let action: () async -> Void

    @State private var pulseVisible = false

    private var monthlyPrice: String {
        let monthly = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        formatter.maximumFractionDigits = 2
        return formatter.string(from: monthly as NSDecimalNumber) ?? ""
    }

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            VStack(spacing: 14) {
                HStack {
                    Text(L10n.text("paywall.product.yearly.trial"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.25)))

                    Spacer()

                    Text(L10n.text("paywall.product.yearly.badge"))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .kerning(0.4)
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayPrice + L10n.text("paywall.product.yearly.period"))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(String.localizedStringWithFormat(
                            L10n.text("paywall.product.yearly.monthly"),
                            monthlyPrice
                        ))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.74))
                    }

                    Spacer()
                }

                Text(L10n.text("paywall.product.yearly.subtitle"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                } else {
                    Text(L10n.text("paywall.product.yearly.cta"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: accentHex))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white)
                        )
                }
            }
            .padding(Theme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .fill(Color(hex: accentHex))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(Color.white, lineWidth: highlight ? 3 : 0)
                    .opacity(pulseVisible ? 0.6 : 0)
            )
            .onAppear {
                guard highlight else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    pulseVisible = true
                }
                withAnimation(.easeInOut(duration: 0.5).delay(0.8)) {
                    pulseVisible = false
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

private struct LifetimeProductCard: View {
    let product: Product
    let accentHex: String
    let isLoading: Bool
    let action: () async -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("paywall.product.lifetime.title"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))

                    Text(L10n.text("paywall.product.lifetime.subtitle"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .tint(Color(hex: accentHex))
                } else {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))
                }
            }
            .padding(Theme.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
            .environmentObject(StoreKitService())
    }
}
