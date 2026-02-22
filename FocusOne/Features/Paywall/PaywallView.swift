import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    Text(L10n.text("paywall.title"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))

                    Text(L10n.text("paywall.subtitle"))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))

                    Card {
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            benefitRow("paywall.benefit.1")
                            benefitRow("paywall.benefit.2")
                            benefitRow("paywall.benefit.3")
                            benefitRow("paywall.benefit.4")
                        }
                    }

                    PrimaryButton(title: L10n.text("paywall.cta"), tintHex: Theme.presets[4].primaryHex) {}
                        .disabled(true)
                        .opacity(0.7)
                }
                .padding(Theme.spacingL)
            }
            .background(Theme.backgroundGradient(for: Theme.presets[4], scheme: colorScheme).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func benefitRow(_ key: String) -> some View {
        Label(L10n.text(key), systemImage: "sparkles")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.textPrimary(for: colorScheme))
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView()
    }
}
