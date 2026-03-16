import SwiftUI

struct SplashView: View {
    let showsIntroFlow: Bool
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var primaryTitle: String {
        showsIntroFlow ? L10n.text("common.cta.get_started") : L10n.text("common.cta.continue")
    }

    private var showsSecondaryAction: Bool {
        showsIntroFlow
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
                        bulletRow(L10n.text("splash.bullet.three"))
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
                    title: primaryTitle,
                    tintHex: Theme.defaultThemeHex,
                    action: onPrimaryAction
                )

                if showsSecondaryAction {
                    Button(L10n.text("common.cta.skip"), action: onSecondaryAction)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
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
        IntroPage(
            titleKey: "intro.page.one.title",
            subtitleKey: "intro.page.one.subtitle",
            kind: .singleFocus
        ),
        IntroPage(
            titleKey: "intro.page.two.title",
            subtitleKey: "intro.page.two.subtitle",
            kind: .streak
        ),
        IntroPage(
            titleKey: "intro.page.three.title",
            subtitleKey: "intro.page.three.subtitle",
            kind: .setup
        )
    ]

    private var isLastPage: Bool {
        currentPage == pages.indices.last
    }

    private var primaryTitle: String {
        isLastPage ? L10n.text("intro.get_started") : L10n.text("common.cta.continue")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FFF0E4"), Color(hex: "FFF9F3")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.spacingL) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        IntroPageCard(page: page)
                            .tag(index)
                            .padding(.horizontal, Theme.padding)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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

                Button(L10n.text("common.cta.skip"), action: onSkip)
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
    let kind: OnboardingVisualKind
}

private struct IntroPageCard: View {
    let page: IntroPage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)

            OnboardingFeatureCardVisual(kind: page.kind)
                .frame(maxWidth: .infinity)

            Text(L10n.text(page.titleKey))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(L10n.text(page.subtitleKey))
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.4), lineWidth: 1)
        )
    }
}

private enum OnboardingVisualKind {
    case singleFocus
    case streak
    case setup
}

private struct OnboardingFeatureCardVisual: View {
    let kind: OnboardingVisualKind

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: Theme.defaultThemeHex).opacity(0.20),
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)

            switch kind {
            case .singleFocus:
                singleFocusVisual
            case .streak:
                streakVisual
            case .setup:
                setupVisual
            }
        }
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 8)
    }

    private var singleFocusVisual: some View {
        VStack(spacing: 14) {
            blurredRow(width: 92, offset: -18, opacity: 0.42)
            activeRow
            blurredRow(width: 78, offset: 18, opacity: 0.42)
        }
        .padding(.horizontal, 26)
    }

    private func blurredRow(width: CGFloat, offset: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(opacity))
            .frame(height: 52)
            .overlay(alignment: .leading) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.white.opacity(0.56))
                        .frame(width: 24, height: 24)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white.opacity(0.72))
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

    private var streakVisual: some View {
        HStack(spacing: 10) {
            ForEach(0..<7, id: \.self) { index in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(streakCellFill(for: index))
                    .frame(height: 74)
                    .overlay {
                        if index == 5 {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: Theme.defaultThemeHex), lineWidth: 2)
                                .padding(2)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Circle()
                            .fill(index < 5 ? Color.white.opacity(0.92) : Color.clear)
                            .frame(width: 8, height: 8)
                            .padding(.bottom, 12)
                    }
            }
        }
        .padding(.horizontal, 22)
    }

    private func streakCellFill(for index: Int) -> Color {
        if index < 5 { return Color(hex: Theme.defaultThemeHex) }
        if index == 5 { return Color(hex: Theme.defaultThemeHex).opacity(0.18) }
        return Color.white.opacity(colorScheme == .dark ? 0.1 : 0.46)
    }

    private var setupVisual: some View {
        VStack(spacing: 14) {
            setupRow(symbol: "textformat", width: 126)
            setupRow(symbol: "sparkles", width: 74)

            HStack(spacing: 12) {
                setupColorDot(Color(hex: Theme.defaultThemeHex))
                setupColorDot(Color(hex: "FFB347"))
                setupColorDot(Color(hex: "34C9A5"))
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

    private func setupColorDot(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 2)
                    .padding(2)
            }
    }
}
