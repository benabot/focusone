import SwiftUI
import CoreData

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showPaywall = false
    @State private var showRemindersSheet = false
    @State private var showDayStartSheet = false
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
        .sheet(isPresented: $showRemindersSheet) {
            SettingsRemindersSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDayStartSheet) {
            SettingsDayStartSheet(viewModel: viewModel)
                .presentationDetents([.medium])
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

                navigationRow(
                    title: L10n.text("settings.reminders"),
                    value: viewModel.remindersSummaryText,
                    action: { showRemindersSheet = true }
                )

                if viewModel.reminderTimes.count < 2 {
                    panelDivider

                    buttonRow(title: L10n.text("settings.add_reminder")) {
                        if viewModel.reminderTimes.count < 2 {
                            viewModel.addReminder()
                        }
                        showRemindersSheet = true
                    }
                }
            }
        }
    }

    private var daySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.day"))

            settingsPanel {
                navigationRow(
                    title: L10n.text("settings.day_start"),
                    value: viewModel.dayStartLabelText,
                    action: { showDayStartSheet = true }
                )
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
                    tintHex: Theme.presets[3].primaryHex
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

    private func navigationRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SettingsValueRow(title: title, value: value) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func buttonRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Spacer(minLength: Theme.spacingS)

                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
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
    let accessory: Accessory

    init(
        title: String,
        value: String? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.value = value
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

            accessory
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, 15)
    }
}

private struct SettingsRemindersSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Toggle(L10n.text("settings.notifications"), isOn: $viewModel.notificationsEnabled)
                        .tint(Theme.accent)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    if viewModel.notificationsEnabled {
                        if !viewModel.reminderTimes.isEmpty {
                            Text(viewModel.reminderTimesText)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                        }

                        ForEach(viewModel.reminderTimes.indices, id: \.self) { index in
                            HStack(spacing: 12) {
                                Text("\(L10n.text("settings.reminder")) \(index + 1)")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                                Spacer()

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
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                                    .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.64))
                            )
                        }

                        if viewModel.reminderTimes.count < 2 {
                            Button {
                                viewModel.addReminder()
                            } label: {
                                Label(L10n.text("settings.add_reminder"), systemImage: "plus")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(L10n.text("settings.reminders"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
            .background(
                Theme.backgroundGradient(for: Theme.presets[6], scheme: colorScheme)
                    .ignoresSafeArea()
            )
        }
    }
}

private struct SettingsDayStartSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var dayStartBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: viewModel.dayStartHour,
                    minute: 0,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                viewModel.dayStartHour = Calendar.current.component(.hour, from: date)
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                DatePicker(
                    L10n.text("settings.day_start"),
                    selection: dayStartBinding,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Text(L10n.dayHourLabel(viewModel.dayStartHour))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Spacer()
            }
            .padding(20)
            .navigationTitle(L10n.text("settings.day_start"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
            .background(
                Theme.backgroundGradient(for: Theme.presets[6], scheme: colorScheme)
                    .ignoresSafeArea()
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(context: PreviewSupport.context)
    }
}
