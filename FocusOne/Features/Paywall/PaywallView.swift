import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showLaunchAlert = false

    private let accentHex = Theme.presets[3].primaryHex

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    header
                    noteCard

                    VStack(spacing: Theme.spacingS) {
                        benefitRow(
                            symbol: "arrow.right.circle.fill",
                            title: L10n.text("paywall.benefit.habits.title"),
                            detail: L10n.text("paywall.benefit.habits.detail")
                        )
                        benefitRow(
                            symbol: "clock.arrow.circlepath",
                            title: L10n.text("paywall.benefit.history.title"),
                            detail: L10n.text("paywall.benefit.history.detail")
                        )
                        benefitRow(
                            symbol: "rectangle.grid.2x2.fill",
                            title: L10n.text("paywall.benefit.widgets.title"),
                            detail: L10n.text("paywall.benefit.widgets.detail")
                        )
                        benefitRow(
                            symbol: "archivebox.fill",
                            title: L10n.text("paywall.benefit.cycles.title"),
                            detail: L10n.text("paywall.benefit.cycles.detail")
                        )
                    }
                }
                .padding(Theme.spacingL)
                .padding(.bottom, 120)
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
            .alert(L10n.text("paywall.alert.title"), isPresented: $showLaunchAlert) {
                Button(L10n.text("common.close"), role: .cancel) {}
            } message: {
                Text(L10n.text("paywall.alert.message"))
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

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.text("paywall.note"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
        )
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
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(spacing: Theme.spacingXS) {
            PrimaryButton(title: L10n.text("paywall.cta"), tintHex: accentHex) {
                showLaunchAlert = true
            }

            Button(L10n.text("paywall.secondary.later")) {
                dismiss()
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
            .buttonStyle(.plain)

            Button(L10n.text("paywall.secondary.restore")) {}
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: accentHex))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.top, Theme.spacingS)
        .padding(.bottom, Theme.spacingS)
        .background(
            Theme.backgroundTint.opacity(colorScheme == .dark ? 0.15 : 0.94)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
