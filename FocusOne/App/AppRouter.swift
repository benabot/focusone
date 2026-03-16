import SwiftUI
import CoreData

struct AppRouter: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage(AppStorageKeys.hasOnboarded) private var hasOnboarded = false

    private enum Route: Equatable {
        case loading, splash, onboarding, mainTabs
    }

    @State private var route: Route = .loading

    var body: some View {
        Group {
            switch route {
            case .loading:
                Color.clear.onAppear(perform: resolveRoute)

            case .splash:
                SplashView(
                    hasActiveHabit: false,
                    onPrimaryAction:   { route = .onboarding },
                    onSecondaryAction: { route = .onboarding }
                )

            case .onboarding:
                OnboardingView(context: context, mode: .create) {
                    hasOnboarded = true
                    route = .mainTabs
                } onCancel: {
                    route = hasOnboarded ? .mainTabs : .splash
                }

            case .mainTabs:
                CustomTabView(context: context)
            }
        }
    }

    private func resolveRoute() {
        let hasHabit = HabitRepository(context: context).fetchActiveHabit() != nil
        if hasHabit              { route = .mainTabs   }
        else if hasOnboarded     { route = .onboarding }
        else                     { route = .splash     }
    }
}

// MARK: - Custom Tab Bar (style Headspace)

private struct CustomTabView: View {
    let context: NSManagedObjectContext
    @State private var selected: Tab = .home
    @Environment(\.colorScheme) private var cs

    enum Tab: Int, CaseIterable {
        case home, projects, stats, settings

        var icon: String {
            switch self {
            case .home:     return "square.grid.2x2.fill"
            case .projects: return "folder.fill"
            case .stats:    return "chart.bar.fill"
            case .settings: return "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Pages (sans animation de tab par défaut)
            Group {
                switch selected {
                case .home:     HomeView(context: context)
                case .projects: ProjectsView(context: context)
                case .stats:    StatsView(context: context)
                case .settings: SettingsView(context: context)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tab bar custom
            tabBar
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Spacer()
                tabButton(tab)
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, safeAreaBottom)
        .background(
            Rectangle()
                .fill(Theme.card(cs))
                .shadow(color: .black.opacity(cs == .dark ? 0.3 : 0.08), radius: 16, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: Tab) -> some View {
        let isSelected = selected == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.preset(for: Theme.defaultThemeHex).softColor)
                            .frame(width: 44, height: 30)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected
                                         ? Color(hex: Theme.defaultThemeHex)
                                         : Theme.fg2(cs))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
                }
                .frame(width: 44, height: 30)

                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isSelected
                                     ? Color(hex: Theme.defaultThemeHex)
                                     : Theme.fg2(cs))
            }
        }
        .buttonStyle(.plain)
    }

    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0)
    }
}

private extension CustomTabView.Tab {
    var label: String {
        switch self {
        case .home:     return "tab.home"
        case .projects: return "tab.projects"
        case .stats:    return "tab.stats"
        case .settings: return "tab.settings"
        }
    }
}

struct AppRouter_Previews: PreviewProvider {
    static var previews: some View {
        AppRouter()
            .environment(\.managedObjectContext, PreviewSupport.context)
    }
}
