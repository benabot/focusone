import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var storeKit: StoreKitService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var purchaseError: String?
    @State private var showError = false

    let highlightYearly: Bool

    private let accentHex = Theme.presets[3].primaryHex

    init(highlightYearly: Bool = false) {
        self.highlightYearly = highlightYearly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    header

                    if !storeKit.products.isEmpty {
                        productCards
                    }

                    benefitsSection
                }
                .padding(Theme.spacingL)
                .padding(.bottom, 80)
            }
            .background(Theme.backgroundGradient(for: Theme.presets[3], scheme: colorScheme).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { footer }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) { dismiss() }
                }
            }
            .alert(L10n.text("paywall.error.title"), isPresented: $showError) {
                Button(L10n.text("common.close"), role: .cancel) {}
            } message: {
                Text(purchaseError ?? "")
            }
        }
        .task { await storeKit.loadProducts() }
        .onChange(of: storeKit.entitlementState) { _, newState in
            if newState == .active { dismiss() }
        }
    }


    // MARK: - Header

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

    // MARK: - Product cards

    private var productCards: some View {
        VStack(spacing: Theme.spacingS) {
            if let yearly = storeKit.yearlyProduct {
                YearlyProductCard(
                    product: yearly,
                    accentHex: accentHex,
                    isLoading: isPurchasing,
                    highlight: highlightYearly
                ) { await buy(yearly) }
            }

            if let lifetime = storeKit.lifetimeProduct {
                LifetimeProductCard(
                    product: lifetime,
                    accentHex: accentHex,
                    isLoading: isPurchasing
                ) { await buy(lifetime) }
            }
        }
    }

    // MARK: - Benefits section

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(L10n.text("paywall.benefits.header"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .kerning(0.4)
                .padding(.leading, 4)

            benefitRow(symbol: "shield.checkered",
                       title: L10n.text("paywall.benefit.streak.title"),
                       detail: L10n.text("paywall.benefit.streak.detail"))
            benefitRow(symbol: "calendar",
                       title: L10n.text("paywall.benefit.history.title"),
                       detail: L10n.text("paywall.benefit.history.detail"))
            benefitRow(symbol: "rectangle.on.rectangle",
                       title: L10n.text("paywall.benefit.widgets.title"),
                       detail: L10n.text("paywall.benefit.widgets.detail"))
            benefitRow(symbol: "arrow.triangle.2.circlepath",
                       title: L10n.text("paywall.benefit.cycles.title"),
                       detail: L10n.text("paywall.benefit.cycles.detail"))
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

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Theme.spacingXS) {
            Button(L10n.text("paywall.secondary.later")) { dismiss() }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .buttonStyle(.plain)

            Button {
                Task { await restore() }
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
        .background(Theme.backgroundTint.opacity(colorScheme == .dark ? 0.15 : 0.94).ignoresSafeArea(edges: .bottom))
    }

    // MARK: - Actions

    private func buy(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        let result = await storeKit.purchase(product)
        switch result {
        case .success: dismiss()
        case .cancelled, .pending: break
        case .failed(let error):
            purchaseError = error.localizedDescription
            showError = true
        }
    }

    private func restore() async {
        isRestoring = true
        await storeKit.restorePurchases()
        isRestoring = false
    }

    // MARK: - Shared style

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
            .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
            )
    }
}

// MARK: - Yearly Product Card

private struct YearlyProductCard: View {
    let product: Product
    let accentHex: String
    let isLoading: Bool
    let highlight: Bool
    let action: () async -> Void

    @Environment(\.colorScheme) private var colorScheme
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
            Task { await action() }
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
                        .foregroundStyle(.white.opacity(0.7))
                        .kerning(0.4)
                }

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayPrice + L10n.text("paywall.product.yearly.period"))
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text(String(format: L10n.text("paywall.product.yearly.monthly"), monthlyPrice))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }

                if isLoading {
                    ProgressView().tint(.white)
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
                withAnimation(.easeInOut(duration: 0.5)) { pulseVisible = true }
                withAnimation(.easeInOut(duration: 0.5).delay(0.8)) { pulseVisible = false }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Lifetime Product Card

private struct LifetimeProductCard: View {
    let product: Product
    let accentHex: String
    let isLoading: Bool
    let action: () async -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))
                    Text(L10n.text("paywall.product.lifetime.subtitle"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                }
                Spacer()
                if isLoading {
                    ProgressView().tint(Color(hex: accentHex))
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
        PaywallView().environmentObject(StoreKitService())
    }
}
