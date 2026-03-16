import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showPaywall = false
    @Environment(\.colorScheme) private var cs

    private var preset: ThemePreset { Theme.preset(for: viewModel.selectedThemeHex) }

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context))
    }

    var body: some View {
        ZStack {
            Theme.canvas(cs).ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    sections
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear(perform: viewModel.load)
        .onChange(of: viewModel.notificationsEnabled) { Task { await viewModel.save() } }
        .onChange(of: viewModel.reminderTimes)        { Task { await viewModel.save() } }
        .onChange(of: viewModel.dayStartHour)         { Task { await viewModel.save() } }
        .onChange(of: viewModel.selectedThemeHex)     { Task { await viewModel.save() } }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: — Hero

    private var hero: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color(hex: preset.softHex).ignoresSafeArea(edges: .top)

                Circle()
                    .fill(Color(hex: preset.primaryHex).opacity(0.15))
                    .frame(width: 150, height: 150)
                    .offset(x: UIScreen.main.bounds.width - 50, y: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("RÉGLAGES")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: preset.primaryHex))
                        .kerning(1.8)
                    Text("Préférences")
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.fg(.light))
                    Text("Devise & notifications")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.fg2(.light))
                }
                .padding(.horizontal, Theme.pad)
                .padding(.top, geo.safeAreaInsets.top + 16)
                .padding(.bottom, 28)
            }
        }
        .frame(height: 160)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: Theme.rXL,
                bottomTrailingRadius: Theme.rXL, topTrailingRadius: 0,
                style: .continuous
            )
        )
    }

    // MARK: — Sections

    private var sections: some View {
        VStack(spacing: 16) {
            currencySection
            themeSection
            notifSection
            cloudSection
            premiumSection
        }
        .padding(Theme.pad)
        .padding(.bottom, 28)
    }

    // MARK: — Devise

    private var currencySection: some View {
        SCard(title: "Devise") {
            SRow(title: "Devise par défaut") {
                Menu("EUR €") {
                    Button("EUR €") {}
                    Button("USD $") {}
                    Button("GBP £") {}
                    Button("CHF ₣") {}
                }
                .font(Theme.body(15, .semibold))
                .foregroundStyle(Color(hex: viewModel.selectedThemeHex))
            }
        }
    }


    // MARK: — Thème

    private var themeSection: some View {
        SCard(title: "Couleur d'accent") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Theme.presets) { p in
                        let sel = viewModel.selectedThemeHex == p.primaryHex
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedThemeHex = p.primaryHex
                            }
                        } label: {
                            ZStack {
                                Circle().fill(Color(hex: p.primaryHex)).frame(width: 38, height: 38)
                                if sel {
                                    Circle().stroke(Color.white, lineWidth: 3).frame(width: 38, height: 38)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .shadow(color: sel ? Color(hex: p.primaryHex).opacity(0.4) : .clear,
                                    radius: 8, x: 0, y: 3)
                            .scaleEffect(sel ? 1.15 : 1)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var notifSection: some View {
        SCard(title: "Notifications") {
            VStack(spacing: 14) {
                SRow(title: "Alertes dépassement budget") {
                    Toggle("", isOn: $viewModel.notificationsEnabled)
                        .labelsHidden()
                        .tint(Color(hex: viewModel.selectedThemeHex))
                }
                if viewModel.notificationsEnabled {
                    Divider().opacity(0.35)
                    ForEach(viewModel.reminderTimes.indices, id: \.self) { i in
                        SRow(title: "Rappel \(i + 1)") {
                            HStack(spacing: 8) {
                                DatePicker("", selection: Binding(
                                    get: { viewModel.reminderTimes[i] },
                                    set: { viewModel.reminderTimes[i] = $0 }
                                ), displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                Button { viewModel.removeReminder(at: i) } label: {
                                    Image(systemName: "minus.circle.fill").font(.system(size: 20))
                                        .foregroundStyle(Color(hex: preset.primaryHex).opacity(0.7))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    if viewModel.reminderTimes.count < 2 {
                        Button { viewModel.addReminder() } label: {
                            Label("Ajouter un rappel", systemImage: "plus.circle.fill")
                                .font(Theme.body(14, .semibold))
                                .foregroundStyle(Color(hex: viewModel.selectedThemeHex))
                        }.buttonStyle(.plain).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: — iCloud

    private var cloudSection: some View {
        SCard(title: "Synchronisation iCloud") {
            HStack(spacing: 10) {
                Image(systemName: "icloud.fill").foregroundStyle(Color(hex: preset.primaryHex))
                Text(viewModel.iCloudStatus).font(Theme.body(14)).foregroundStyle(Theme.fg2(cs))
            }
        }
    }

    // MARK: — Premium

    private var premiumSection: some View {
        SCard(title: "Premium") {
            PrimaryButton(title: "Découvrir BudgetOne Pro", tintHex: preset.primaryHex) { showPaywall = true }
        }
    }
}

// MARK: - SCard

private struct SCard<C: View>: View {
    let title: String
    let content: C
    @Environment(\.colorScheme) private var cs

    init(title: String, @ViewBuilder content: () -> C) {
        self.title = title; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.fg2(cs))
                .kerning(1.2)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                .fill(Theme.card(cs))
                .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 5)
        )
    }
}

// MARK: - SRow

private struct SRow<C: View>: View {
    let title: String
    let content: C
    @Environment(\.colorScheme) private var cs

    init(title: String, @ViewBuilder content: () -> C) {
        self.title = title; self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.body(15, .medium))
                .foregroundStyle(Theme.fg(cs))
            Spacer(minLength: 8)
            content
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(context: PreviewSupport.context)
    }
}
