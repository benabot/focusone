import SwiftUI

struct AppRouter: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage(AppStorageKeys.hasOnboarded) private var hasOnboarded = false
    @State private var hasActiveHabit = false
    @State private var route: Route = .splash

    private enum Route: Equatable {
        case splash
        case onboarding
        case mainTabs
    }

    var body: some View {
        Group {
            switch route {
            case .splash:
                SplashView(
                    hasActiveHabit: hasActiveHabit,
                    onPrimaryAction: handleSplashAction,
                    onSecondaryAction: handleSplashAction
                )
            case .onboarding:
                OnboardingView(
                    context: context,
                    mode: .create
                ) {
                    hasOnboarded = true
                    reload()
                    route = hasActiveHabit ? .mainTabs : .splash
                } onCancel: {
                    route = .splash
                }
            case .mainTabs:
                mainTabs
            }
        }
        .onAppear {
            reload()
            route = .splash
        }
        .onChange(of: hasActiveHabit) {
            if route == .mainTabs || route == .splash {
                return
            }
            route = hasActiveHabit ? .mainTabs : .splash
        }
    }

    private func handleSplashAction() {
        if hasActiveHabit {
            hasOnboarded = true
            route = .mainTabs
        } else {
            route = .onboarding
        }
    }

    private func reload() {
        hasActiveHabit = HabitRepository(context: context).fetchActiveHabit() != nil
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
