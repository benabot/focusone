import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showPaywall = false
    @Environment(\.colorScheme) private var colorScheme

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context))
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: Theme.presets[6], scheme: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    Text(L10n.text("settings.title"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))

                    notificationsSection
                    daySection
                    themeSection
                    cloudSection
                    premiumSection
                }
                .padding(Theme.padding)
            }
        }
        .onAppear(perform: viewModel.load)
        .onChange(of: viewModel.notificationsEnabled) {
            Task { await viewModel.save() }
        }
        .onChange(of: viewModel.reminderTimes) {
            Task { await viewModel.save() }
        }
        .onChange(of: viewModel.dayStartHour) {
            Task { await viewModel.save() }
        }
        .onChange(of: viewModel.selectedThemeHex) {
            Task { await viewModel.save() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.notifications"))

            SettingsRow(title: L10n.text("settings.notifications")) {
                Toggle(L10n.text("settings.notifications"), isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
            }

            if viewModel.notificationsEnabled {
                ForEach(viewModel.reminderTimes.indices, id: \.self) { index in
                    SettingsRow(title: "\(L10n.text("settings.reminder")) \(index + 1)") {
                        HStack(spacing: Theme.spacingXS) {
                            DatePicker(
                                L10n.text("settings.reminder"),
                                selection: Binding(
                                    get: { viewModel.reminderTimes[index] },
                                    set: { viewModel.reminderTimes[index] = $0 }
                                ),
                                displayedComponents: [.hourAndMinute]
                            )
                            .labelsHidden()

                            Spacer(minLength: 0)

                            Button(L10n.text("common.remove")) {
                                viewModel.removeReminder(at: index)
                            }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .buttonStyle(.plain)
                        }
                    }
                }

                if viewModel.reminderTimes.count < 2 {
                    Button {
                        viewModel.addReminder()
                    } label: {
                        Label(L10n.text("settings.add_reminder"), systemImage: "plus")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary(for: colorScheme))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var daySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.day_start"))

            SettingsRow(title: L10n.text("settings.day_start")) {
                Menu(L10n.dayHourLabel(viewModel.dayStartHour)) {
                    ForEach(0..<24, id: \.self) { hour in
                        Button(L10n.dayHourLabel(hour)) {
                            viewModel.dayStartHour = hour
                        }
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.theme"))

            SettingsRow(title: L10n.text("settings.theme")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.spacingS) {
                        ForEach(Theme.presets) { preset in
                            let isSelected = viewModel.selectedThemeHex == preset.primaryHex

                            Button {
                                viewModel.selectedThemeHex = preset.primaryHex
                            } label: {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Circle()
                                            .stroke(.white, lineWidth: isSelected ? 2 : 0)
                                    }
                                    .overlay {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var cloudSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.icloud"))
            Text(viewModel.iCloudStatus)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
        }
    }

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.premium"))

            PrimaryButton(
                title: L10n.text("settings.open_paywall"),
                tintHex: Theme.presets[4].primaryHex
            ) {
                showPaywall = true
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Spacer(minLength: Theme.spacingS)

            content
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.62))
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(context: PreviewSupport.context)
    }
}
