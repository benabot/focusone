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
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.text("settings.title"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))

                    remindersSection
                    daySection
                    appearanceSection
                    syncSection
                    premiumSection
                }
                .padding(Theme.padding)
                .padding(.bottom, 24)
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

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.reminders"))

            settingsPanel {
                SettingsValueRow(title: L10n.text("settings.notifications"), value: viewModel.notificationsStatusText) {
                    Toggle(L10n.text("settings.notifications"), isOn: $viewModel.notificationsEnabled)
                        .labelsHidden()
                }

                panelDivider

                SettingsValueRow(
                    title: L10n.text("settings.reminders"),
                    value: viewModel.remindersSummaryText,
                    actionTitle: viewModel.reminderTimes.count < 2 ? L10n.text("settings.add_reminder") : nil,
                    actionTint: Theme.accent,
                    action: {
                        if viewModel.reminderTimes.count < 2 {
                            viewModel.addReminder()
                        }
                    }
                ) {
                }

                if viewModel.notificationsEnabled {
                    ForEach(viewModel.reminderTimes.indices, id: \.self) { index in
                        panelDivider

                        reminderEditorRow(index: index)
                    }
                }
            }
        }
    }

    private var daySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.day"))

            settingsPanel {
                SettingsValueRow(title: L10n.text("settings.day_start"), value: viewModel.dayStartLabelText) {
                    Menu(viewModel.dayStartLabelText) {
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
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.appearance"))

            settingsPanel {
                SettingsValueRow(title: L10n.text("settings.theme"), value: viewModel.selectedThemeName)

                panelDivider

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.spacingS) {
                        ForEach(Theme.presets) { preset in
                            let isSelected = viewModel.selectedThemeHex == preset.primaryHex

                            Button {
                                viewModel.selectedThemeHex = preset.primaryHex
                            } label: {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            Circle()
                                                .stroke(.white, lineWidth: isSelected ? 2 : 0)
                                        }
                                        .overlay {
                                            if isSelected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }

                                    Text(L10n.text(preset.nameKey))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                                }
                                .frame(width: 52)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.spacingM)
                }
            }
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.sync"))

            settingsPanel {
                SettingsValueRow(title: L10n.text("settings.icloud"), value: viewModel.iCloudStatus)
            }
        }
    }

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.premium"))

            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.text("settings.premium.card.title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Text(L10n.text("settings.premium.card.subtitle"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(
                    title: L10n.text("settings.open_paywall"),
                    tintHex: Theme.presets[4].primaryHex
                ) {
                    showPaywall = true
                }
            }
            .padding(Theme.spacingM)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.64))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
            )
        }
    }

    private func reminderEditorRow(index: Int) -> some View {
        HStack(spacing: Theme.spacingS) {
            Text("\(L10n.text("settings.reminder")) \(index + 1)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Spacer(minLength: Theme.spacingS)

            DatePicker(
                L10n.text("settings.reminder"),
                selection: Binding(
                    get: { viewModel.reminderTimes[index] },
                    set: { viewModel.reminderTimes[index] = $0 }
                ),
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()

            Button(L10n.text("common.remove")) {
                viewModel.removeReminder(at: index)
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
    }

    private func settingsPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
    }

    private var panelDivider: some View {
        Divider()
            .overlay(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.75))
            .padding(.horizontal, Theme.spacingM)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }
}

private struct SettingsValueRow<Accessory: View>: View {
    let title: String
    let value: String?
    let actionTitle: String?
    let actionTint: Color
    let action: (() -> Void)?
    let accessory: Accessory

    init(
        title: String,
        value: String? = nil,
        actionTitle: String? = nil,
        actionTint: Color = Theme.accent,
        action: (() -> Void)? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.value = value
        self.actionTitle = actionTitle
        self.actionTint = actionTint
        self.action = action
        self.accessory = accessory()
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.spacingS) {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Spacer(minLength: Theme.spacingS)

            if let value {
                Text(value)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .lineLimit(1)
            }

            if let actionTitle {
                Button(actionTitle) {
                    action?()
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(actionTint)
                .buttonStyle(.plain)
            }

            accessory
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, 15)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(context: PreviewSupport.context)
    }
}
