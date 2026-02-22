import SwiftUI

struct SplashView: View {
    let hasActiveHabit: Bool
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var secondaryTitle: String {
        hasActiveHabit ? L10n.text("common.cta.continue") : L10n.text("common.cta.skip")
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: Theme.presets[1], scheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    splashArtwork
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.spacingM)

                    Text(L10n.text("splash.title"))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))

                    Text(L10n.text("splash.subtitle"))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Theme.spacingXS) {
                        bulletRow(L10n.text("splash.bullet.one"))
                        bulletRow(L10n.text("splash.bullet.two"))
                    }

                    Spacer(minLength: Theme.spacingXL)
                }
                .padding(Theme.padding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.spacingXS) {
                PrimaryButton(
                    title: L10n.text("common.cta.get_started"),
                    tintHex: Theme.defaultThemeHex,
                    action: onPrimaryAction
                )

                Button(secondaryTitle, action: onSecondaryAction)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
            }
            .padding(.horizontal, Theme.padding)
            .padding(.top, Theme.spacingS)
            .padding(.bottom, Theme.spacingS)
            .background(
                Theme.backgroundTint.opacity(colorScheme == .dark ? 0.15 : 0.92)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(Theme.textSecondary(for: colorScheme).opacity(0.8))

            Text(text)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
        }
    }

    private var splashArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFE2D1"),
                            Color(hex: "FFDDB6"),
                            Color(hex: "CCECFF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 120, height: 120)
                .offset(x: -96, y: -56)

            Circle()
                .fill(Color(hex: "FF8A5B").opacity(0.3))
                .frame(width: 96, height: 96)
                .offset(x: 94, y: 58)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.44))
                .frame(width: 154, height: 84)
                .offset(x: 12, y: -8)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 8)
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashView(hasActiveHabit: false, onPrimaryAction: {}, onSecondaryAction: {})
            SplashView(hasActiveHabit: true, onPrimaryAction: {}, onSecondaryAction: {})
        }
    }
}
