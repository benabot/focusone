import SwiftUI

struct AppRouter: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage(AppStorageKeys.hasOnboarded) private var hasOnboarded = false

    private enum Route: Equatable {
        case loading
        case splash
        case onboarding
        case mainTabs
    }

    @State private var route: Route = .loading

    var body: some View {
        Group {
            switch route {
            case .loading:
                loadingView

            case .splash:
                SplashView(
                    hasActiveHabit: false,
                    onPrimaryAction: { route = .onboarding },
                    onSecondaryAction: { route = .onboarding }
                )

            case .onboarding:
                OnboardingView(
                    context: context,
                    mode: .create
                ) {
                    hasOnboarded = true
                    route = .mainTabs
                } onCancel: {
                    route = hasOnboarded ? .mainTabs : .splash
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
        let hasHabit = HabitRepository(context: context).fetchActiveHabit() != nil
        if hasHabit {
            route = .mainTabs
        } else if hasOnboarded {
            // already onboarded but habit was deleted — back to onboarding
            route = .onboarding
        } else {
            route = .splash
        }
    }

    private var mainTabs: some View {
        TabView {
            HomeView(context: context)
                .tabItem { Label(L10n.text("tab.home"), systemImage: "house.fill") }

            StatsView(context: context)
                .tabItem { Label(L10n.text("tab.stats"), systemImage: "chart.bar.fill") }

            SettingsView(context: context)
                .tabItem { Label(L10n.text("tab.settings"), systemImage: "gearshape.fill") }
        }
    }
}

struct AppRouter_Previews: PreviewProvider {
    static var previews: some View {
        AppRouter()
            .environment(\.managedObjectContext, PreviewSupport.context)
    }
}
