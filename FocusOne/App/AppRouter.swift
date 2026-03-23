import SwiftUI

struct AppRouter: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var storeKit: StoreKitService
    @AppStorage(AppStorageKeys.hasOnboarded) private var hasOnboarded = false

    private enum Route: Equatable {
        case loading
        case splash
        case intro
        case onboarding
        case mainTabs
    }

    enum MainTab: String, CaseIterable, Identifiable {
        case home
        case stats
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home:
                return L10n.text("tab.home")
            case .stats:
                return L10n.text("tab.stats")
            case .settings:
                return L10n.text("tab.settings")
            }
        }

        var symbol: String {
            switch self {
            case .home:
                return "house.fill"
            case .stats:
                return "chart.bar.fill"
            case .settings:
                return "slider.horizontal.3"
            }
        }
    }

    @State private var route: Route = .loading
    @State private var hasActiveHabit = false
    @State private var selectedTab: MainTab = .home
    @State private var premiumPrompt: PremiumPromptKind?
    @State private var showPaywall = false
    @State private var paywallHighlightYearly = false
    @State private var premiumPromptCheckToken = 0

    var body: some View {
        Group {
            switch route {
            case .loading:
                loadingView

            case .splash:
                SplashView(
                    showsIntroFlow: shouldShowIntro,
                    onPrimaryAction: handleSplashPrimaryAction,
                    onSecondaryAction: handleSplashSecondaryAction
                )

            case .intro:
                IntroWalkthroughView {
                    route = .onboarding
                } onSkip: {
                    route = .onboarding
                }

            case .onboarding:
                OnboardingView(
                    context: context,
                    mode: .create
                ) {
                    hasOnboarded = true
                    refreshHabitState()
                    route = .mainTabs
                } onCancel: {
                    route = .splash
                }

            case .mainTabs:
                mainTabs
            }
        }
        .onChange(of: route) { newRoute in
            guard newRoute == .mainTabs else { return }
            premiumPromptCheckToken += 1
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            premiumPromptCheckToken += 1
        }
        .task(id: premiumPromptCheckToken) {
            guard premiumPromptCheckToken > 0 else { return }
            await storeKit.updateEntitlementState()
            AppGroupStorage.shared.updateAdvancedWidgetsAccess(
                PremiumGate(storeKitEntitlementState: storeKit.entitlementState).canAccess(.advancedWidgets)
            )
            try? await Task.sleep(nanoseconds: 250_000_000)
            await maybePresentPremiumPromptIfNeeded()
        }
        .sheet(item: $premiumPrompt) { prompt in
            let content = premiumPromptContent(for: prompt)
            PremiumLifecycleSheet(
                badge: content.badge,
                title: content.title,
                message: content.body,
                secondary: content.secondary,
                primaryTitle: content.primaryTitle,
                dismissTitle: content.dismissTitle,
                accentHex: Theme.presets[3].primaryHex
            ) {
                paywallHighlightYearly = prompt == .endingSoon || prompt == .expired
                premiumPrompt = nil
                showPaywall = true
            } onDismiss: {
                premiumPrompt = nil
            } onAppear: {
                markPromptAsShown(prompt)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(highlightYearly: paywallHighlightYearly)
                .environmentObject(storeKit)
        }
    }

    private var loadingView: some View {
        VStack(spacing: Theme.spacingS) {
            ProgressView()
                .controlSize(.large)

            Text("Chargement...")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: .light))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFE7D7"), Color(hex: "FFF7EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            guard route == .loading else { return }
            resolveRoute()
        }
    }

    @MainActor
    private func resolveRoute() {
        refreshHabitState()
        route = shouldSkipSplashForDebug ? resumeRoute : .splash
    }

    @MainActor
    private func handleSplashPrimaryAction() {
        if shouldShowIntro {
            route = .intro
        } else {
            route = resumeRoute
        }
    }

    @MainActor
    private func handleSplashSecondaryAction() {
        route = resumeRoute
    }

    @MainActor
    private func refreshHabitState() {
        hasActiveHabit = HabitRepository(context: context).fetchActiveHabit() != nil
    }

    private var shouldShowIntro: Bool {
        !hasOnboarded && !hasActiveHabit
    }

    private var shouldSkipSplashForDebug: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-SkipSplashForDebug")
        #else
        false
        #endif
    }

    private var resumeRoute: Route {
        hasActiveHabit ? .mainTabs : .onboarding
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView(context: context)
                .tag(MainTab.home)

            StatsView(context: context)
                .tag(MainTab.stats)

            SettingsView(context: context)
                .tag(MainTab.settings)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            CompactTabBar(selection: $selectedTab)
                .padding(.horizontal, Theme.padding)
                .padding(.top, Theme.spacingXS)
                .padding(.bottom, Theme.spacingXS)
        }
        .onAppear {
            premiumPromptCheckToken += 1
        }
    }

    @MainActor
    private func maybePresentPremiumPromptIfNeeded() {
        guard route == .mainTabs, premiumPrompt == nil, !showPaywall else { return }

        let premiumGate = PremiumGate(storeKitEntitlementState: storeKit.entitlementState)
        guard let prompt = premiumGate.pendingLifecyclePrompt() else { return }
        premiumPrompt = prompt
    }

    @MainActor
    private func markPromptAsShown(_ prompt: PremiumPromptKind) {
        var premiumGate = PremiumGate(storeKitEntitlementState: storeKit.entitlementState)
        premiumGate.markPromptShown(prompt)
    }

    private func premiumPromptContent(for prompt: PremiumPromptKind) -> PremiumPromptContent {
        let gate = PremiumGate()

        switch prompt {
        case .midTrial:
            let endDate = gate.trialEndDateString() ?? ""
            let daysLeft = gate.daysRemainingText() ?? ""
            let bodyFormat = L10n.text("premium.prompt.trial.body")
            let secondaryFormat = L10n.text("premium.prompt.trial.secondary.format")
            return PremiumPromptContent(
                badge: L10n.text("premium.trial.badge"),
                title: L10n.text("premium.prompt.trial.title"),
                body: String.localizedStringWithFormat(bodyFormat, endDate),
                secondary: String.localizedStringWithFormat(secondaryFormat, daysLeft, endDate),
                primaryTitle: L10n.text("premium.prompt.trial.cta"),
                dismissTitle: L10n.text("premium.prompt.trial.dismiss")
            )
        case .endingSoon:
            return PremiumPromptContent(
                badge: L10n.text("premium.trial.badge"),
                title: L10n.text("premium.prompt.ending.title"),
                body: L10n.text("premium.prompt.ending.body"),
                secondary: L10n.text("premium.prompt.ending.secondary"),
                primaryTitle: L10n.text("premium.prompt.ending.cta"),
                dismissTitle: L10n.text("premium.prompt.ending.dismiss")
            )
        case .expired:
            return PremiumPromptContent(
                badge: L10n.text("paywall.badge"),
                title: L10n.text("premium.prompt.expired.title"),
                body: L10n.text("premium.prompt.expired.body"),
                secondary: L10n.text("premium.prompt.expired.secondary"),
                primaryTitle: L10n.text("premium.prompt.expired.cta"),
                dismissTitle: L10n.text("premium.prompt.expired.dismiss")
            )
        }
    }
}

struct AppRouter_Previews: PreviewProvider {
    static var previews: some View {
        AppRouter()
            .environment(\.managedObjectContext, PreviewSupport.context)
            .environmentObject(StoreKitService())
    }
}

private struct CompactTabBar: View {
    @Binding var selection: AppRouter.MainTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppRouter.MainTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: .semibold))

                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == tab ? .white : Theme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selection == tab ? Theme.accent : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.75), lineWidth: 1)
        )
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.18 : 0.08),
            radius: 18,
            x: 0,
            y: 10
        )
    }
}

private struct PremiumPromptContent {
    let badge: String
    let title: String
    let body: String
    let secondary: String
    let primaryTitle: String
    let dismissTitle: String
}

private struct PremiumLifecycleSheet: View {
    let badge: String
    let title: String
    let message: String
    let secondary: String
    let primaryTitle: String
    let dismissTitle: String
    let accentHex: String
    let onPrimaryAction: () -> Void
    let onDismiss: () -> Void
    let onAppear: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingL) {
            Text(badge)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: accentHex))
                .kerning(0.8)

            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Text(message)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text(secondary)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Theme.spacingXS) {
                PrimaryButton(title: primaryTitle, tintHex: accentHex, action: onPrimaryAction)

                Button(dismissTitle, action: onDismiss)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .buttonStyle(.plain)
            }
        }
        .padding(Theme.spacingL)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.backgroundGradient(for: Theme.presets[3], scheme: colorScheme).ignoresSafeArea())
        .onAppear(perform: onAppear)
    }
}
