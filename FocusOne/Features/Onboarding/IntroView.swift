import SwiftUI

struct SplashView: View {
    let showsIntroFlow: Bool
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var primaryTitle: String {
        showsIntroFlow ? L10n.text("common.cta.get_started") : L10n.text("common.cta.continue")
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: Theme.presets[1], scheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    SplashShowcaseCard()
                        .padding(.top, AppSpacing.m)

                    Text(L10n.text("splash.title"))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary(for: colorScheme))

                    Text(L10n.text("splash.subtitle"))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        splashBullet(L10n.text("splash.bullet.one"))
                        splashBullet(L10n.text("splash.bullet.two"))
                        splashBullet(L10n.text("splash.bullet.three"))
                    }
                }
                .padding(Theme.padding)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.spacingXS) {
                PrimaryButton(
                    title: primaryTitle,
                    tintHex: Theme.defaultThemeHex,
                    action: onPrimaryAction
                )

                if showsIntroFlow {
                    Button(L10n.text("common.cta.skip"), action: onSecondaryAction)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary(for: colorScheme))
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                }
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

    private func splashBullet(_ text: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary(for: colorScheme).opacity(0.8))

            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary(for: colorScheme))
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashView(showsIntroFlow: true, onPrimaryAction: {}, onSecondaryAction: {})
            SplashView(showsIntroFlow: false, onPrimaryAction: {}, onSecondaryAction: {})
        }
    }
}

struct IntroWalkthroughView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0

    private let pages: [IntroPage] = [
        IntroPage(titleKey: "intro.page.one.title", subtitleKey: "intro.page.one.subtitle", kind: .singleFocus),
        IntroPage(titleKey: "intro.page.two.title", subtitleKey: "intro.page.two.subtitle", kind: .streak),
        IntroPage(titleKey: "intro.page.three.title", subtitleKey: "intro.page.three.subtitle", kind: .setup)
    ]

    private var isLastPage: Bool {
        currentPage == pages.indices.last
    }

    private var primaryTitle: String {
        isLastPage ? L10n.text("intro.get_started") : L10n.text("intro.continue")
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: Theme.presets[0], scheme: colorScheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.spacingL) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 0) {
                            OnboardingFeatureCard(
                                title: L10n.text(page.titleKey),
                                message: L10n.text(page.subtitleKey)
                            ) {
                                switch page.kind {
                                case .singleFocus:
                                    SingleFocusVisual()
                                case .streak:
                                    StreakTrackVisual()
                                case .setup:
                                    SetupStepsVisual()
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .tag(index)
                        .padding(.horizontal, Theme.padding)
                        .padding(.top, Theme.spacingXS)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color(hex: Theme.defaultThemeHex) : Color.white.opacity(0.72))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.78), value: currentPage)
                .padding(.horizontal, Theme.padding)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Theme.spacingXS) {
                PrimaryButton(
                    title: primaryTitle,
                    tintHex: Theme.defaultThemeHex,
                    action: handlePrimaryAction
                )

                Button(L10n.text("intro.skip"), action: onSkip)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary(for: colorScheme))
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

    private func handlePrimaryAction() {
        guard !isLastPage else {
            onContinue()
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            currentPage += 1
        }
    }
}

private struct IntroPage {
    let titleKey: String
    let subtitleKey: String
    let kind: IntroVisualKind
}

private enum IntroVisualKind {
    case singleFocus
    case streak
    case setup
}

private struct SplashShowcaseCard: View {
    var body: some View {
        AppSurface(padding: AppSpacing.l) {
            VStack(spacing: AppSpacing.m) {
                activeRoutineRow
                streakRow
                setupRow
            }
        }
    }

    private var activeRoutineRow: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(hex: Theme.defaultThemeHex))
            .frame(height: 70)
            .overlay(alignment: .leading) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.94))
                            .frame(width: 118, height: 11)

                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.54))
                            .frame(width: 86, height: 9)
                    }
                }
                .padding(.leading, 20)
            }
    }

    private var streakRow: some View {
        HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(index < 5 ? Color(hex: Theme.defaultThemeHex) : Color(hex: Theme.defaultThemeHex).opacity(index == 5 ? 0.2 : 0.08))
                    .frame(height: 56)
            }
        }
    }

    private var setupRow: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.76))
                .frame(height: 48)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(hex: "D9C6B8"))
                        .frame(width: 108, height: 10)
                        .padding(.leading, 16)
                }

            HStack(spacing: 8) {
                ForEach(Array(Theme.freePresets.prefix(3)), id: \.id) { preset in
                    Circle()
                        .fill(Color(hex: preset.primaryHex))
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(Color.white.opacity(0.72), in: Capsule())
        }
    }
}

private struct SingleFocusVisual: View {
    var body: some View {
        VStack(spacing: 14) {
            mutedRow(width: 92, offset: -18)
            activeRow
            mutedRow(width: 78, offset: 18)
        }
        .padding(.horizontal, 26)
    }

    private func mutedRow(width: CGFloat, offset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.46))
            .frame(height: 52)
            .overlay(alignment: .leading) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.white.opacity(0.58))
                        .frame(width: 24, height: 24)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(0.74))
                        .frame(width: width, height: 10)
                }
                .padding(.leading, 18)
            }
            .offset(x: offset)
    }

    private var activeRow: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(hex: Theme.defaultThemeHex))
            .frame(height: 74)
            .overlay(alignment: .leading) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.94))
                            .frame(width: 112, height: 11)

                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.52))
                            .frame(width: 72, height: 9)
                    }
                }
                .padding(.leading, 20)
            }
    }
}

private struct StreakTrackVisual: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(fill(for: index))
                    .frame(height: 74)
                    .overlay {
                        if index == 5 {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: Theme.defaultThemeHex), lineWidth: 2)
                                .padding(2)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if index < 5 {
                            Circle()
                                .fill(Color.white.opacity(0.92))
                                .frame(width: 8, height: 8)
                                .padding(.bottom, 12)
                        }
                    }
            }
        }
        .padding(.horizontal, 22)
    }

    private func fill(for index: Int) -> Color {
        if index < 5 { return Color(hex: Theme.defaultThemeHex) }
        if index == 5 { return Color(hex: Theme.defaultThemeHex).opacity(0.18) }
        return Color.white.opacity(colorScheme == .dark ? 0.10 : 0.46)
    }
}

private struct SetupStepsVisual: View {
    var body: some View {
        VStack(spacing: 14) {
            setupRow(symbol: "textformat", width: 126)
            setupRow(symbol: "sparkles", width: 74)

            HStack(spacing: 12) {
                ForEach(Array(Theme.freePresets.prefix(3)), id: \.id) { preset in
                    colorDot(preset.primaryHex)
                }
            }
        }
        .padding(.horizontal, 28)
    }

    private func setupRow(symbol: String, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.58))
            .frame(height: 52)
            .overlay(alignment: .leading) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: Theme.defaultThemeHex).opacity(0.18))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: Theme.defaultThemeHex))
                        }

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(hex: "D9C6B8"))
                        .frame(width: width, height: 10)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
            }
    }

    private func colorDot(_ hex: String) -> some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 28, height: 28)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.92), lineWidth: 2)
                    .padding(2)
            }
    }
}
