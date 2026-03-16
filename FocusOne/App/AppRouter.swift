import SwiftUI

struct AppRouter: View {
    @Environment(\.managedObjectContext) private var context
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
        route = .splash
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
    }
}

struct AppRouter_Previews: PreviewProvider {
    static var previews: some View {
        AppRouter()
            .environment(\.managedObjectContext, PreviewSupport.context)
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
