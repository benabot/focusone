import SwiftUI
import CoreData

struct SettingsView: View {
    private let context: NSManagedObjectContext
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var storeKit: StoreKitService
    @State private var showPaywall = false
    #if DEBUG
    @State private var debugConfirmation: String?
    #endif
    @State private var showRemindersSheet = false
    @State private var showDayStartSheet = false
    @State private var showICloudSheet = false
    @State private var showArchivesSheet = false
    @State private var showUpcomingRoutinesSheet = false
    @State private var gateFeature: PremiumFeature?
    @Environment(\.colorScheme) private var colorScheme

    init(context: NSManagedObjectContext) {
        self.context = context
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context))
    }

    private var customizationUnlocked: Bool {
        PremiumGate(storeKitEntitlementState: storeKit.entitlementState).canAccess(.customization)
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

                    #if DEBUG
                    debugPremiumSection
                    #endif
                }
                .padding(Theme.padding)
                .padding(.bottom, 116)
            }
        }
        .onAppear {
            viewModel.load(
                allowPremiumThemes: customizationUnlocked,
                storeKitState: storeKit.entitlementState
            )
        }
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
        .onChange(of: storeKit.entitlementState) { _ in
            viewModel.refreshPremiumState(storeKitState: storeKit.entitlementState)
            AppGroupStorage.shared.updateAdvancedWidgetsAccess(
                PremiumGate(storeKitEntitlementState: storeKit.entitlementState).canAccess(.advancedWidgets)
            )
            viewModel.load(
                allowPremiumThemes: customizationUnlocked,
                storeKitState: storeKit.entitlementState
            )
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            viewModel.refreshPremiumState(storeKitState: storeKit.entitlementState)
        }) {
            PaywallView()
                .environmentObject(storeKit)
        }
        .sheet(isPresented: $showRemindersSheet) {
            SettingsRemindersSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDayStartSheet) {
            SettingsDayStartSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showICloudSheet) {
            SettingsInfoSheet(
                title: L10n.text("settings.icloud"),
                message: viewModel.iCloudInfoMessage
            )
        }
        .sheet(isPresented: $showArchivesSheet) {
            SettingsArchivesSheet(items: viewModel.archivedRoutines)
        }
        .sheet(isPresented: $showUpcomingRoutinesSheet, onDismiss: {
            viewModel.loadUpcomingRoutines()
        }) {
            SettingsUpcomingRoutinesSheet(
                context: context,
                viewModel: viewModel,
                onActivateRoutine: { id in
                    await viewModel.activateUpcomingRoutine(id: id)
                }
            )
        }
        .alert(item: $gateFeature) { feature in
            Alert(
                title: Text(L10n.text(feature.gateTitleKey)),
                message: Text(L10n.text(feature.gateMessageKey)),
                primaryButton: .default(Text(L10n.text("premium.gate.cta"))) {
                    showPaywall = true
                },
                secondaryButton: .cancel(Text(L10n.text("premium.gate.dismiss")))
            )
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
                SettingsValueRow(title: L10n.text("settings.theme"))

                panelDivider

                ThemePalettePicker(
                    selectedHex: viewModel.selectedThemeHex,
                    canAccessPremiumThemes: customizationUnlocked
                ) { hex in
                    viewModel.selectedThemeHex = hex
                } onLockedTap: {
                    showPaywall = true
                }

                if !customizationUnlocked {
                    panelDivider

                    SettingsValueRow(
                        title: L10n.text("settings.theme.premium_note"),
                        value: L10n.text("settings.theme.free_palette")
                    )
                }
            }
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.sync"))

            settingsPanel {
                navigationRow(
                    title: L10n.text("settings.icloud"),
                    value: viewModel.iCloudStatus,
                    action: { showICloudSheet = true }
                )
            }
        }
    }

    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle(L10n.text("settings.section.premium"))

            VStack(alignment: .leading, spacing: 14) {
                Text(viewModel.premiumCardTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Text(viewModel.premiumCardSubtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                if let footnote = viewModel.premiumCardFootnote {
                    Text(footnote)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: Theme.presets[3].primaryHex))
                }

                PrimaryButton(
                    title: viewModel.premiumButtonTitle,
                    tintHex: Theme.presets[3].primaryHex
                ) {
                    showPaywall = true
                }

                panelDivider

                contextActionRow(title: L10n.text("settings.premium.context.archives")) {
                    openPremiumContext(.archives)
                }

                panelDivider

                contextActionRow(title: L10n.text("settings.premium.context.next")) {
                    openPremiumContext(.nextRoutine)
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

    #if DEBUG
    private var debugPremiumSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            sectionTitle("DEBUG - Premium")

            settingsPanel {
                debugButton("Simulate trial day 1") {
                    setTrialStart(daysAgo: 0)
                }

                panelDivider

                debugButton("Simulate trial day 6") {
                    setTrialStart(daysAgo: 6)
                }

                panelDivider

                debugButton("Simulate last trial day") {
                    setTrialStart(daysAgo: 9)
                }

                panelDivider

                debugButton("Simulate expired trial") {
                    setTrialStart(daysAgo: 11)
                }

                panelDivider

                debugButton("Reset premium state") {
                    let defaults = UserDefaults.standard
                    defaults.removeObject(forKey: AppStorageKeys.premiumTrialStartedAt)
                    defaults.removeObject(forKey: AppStorageKeys.isPremium)
                    defaults.removeObject(forKey: AppStorageKeys.premiumPromptMidShownDay)
                    defaults.removeObject(forKey: AppStorageKeys.premiumPromptEndingShownDay)
                    defaults.removeObject(forKey: AppStorageKeys.premiumPromptExpiredShown)
                    debugConfirmation = "Premium state reset"
                }
            }

            if let debugConfirmation {
                Text(debugConfirmation)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
    }

    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            viewModel.refreshPremiumState(storeKitState: storeKit.entitlementState)
            AppGroupStorage.shared.updateAdvancedWidgetsAccess(
                PremiumGate(storeKitEntitlementState: storeKit.entitlementState).canAccess(.advancedWidgets)
            )

            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation {
                        debugConfirmation = nil
                    }
                }
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Spacer()
            }
            .padding(.horizontal, Theme.spacingM)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func setTrialStart(daysAgo: Int) {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        let start = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        )

        defaults.set(start.timeIntervalSince1970, forKey: AppStorageKeys.premiumTrialStartedAt)
        defaults.removeObject(forKey: AppStorageKeys.premiumPromptMidShownDay)
        defaults.removeObject(forKey: AppStorageKeys.premiumPromptEndingShownDay)
        defaults.removeObject(forKey: AppStorageKeys.premiumPromptExpiredShown)

        let remaining = max(0, 10 - daysAgo)
        debugConfirmation = "Trial -> day \(daysAgo + 1)/10 (\(remaining)d left)"
    }
    #endif

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

    private func contextActionRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Spacer(minLength: Theme.spacingS)

                Image(systemName: "chevron.right")
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

    private func openPremiumContext(_ feature: PremiumFeature) {
        let gate = PremiumGate(storeKitEntitlementState: storeKit.entitlementState)

        guard gate.canAccess(feature) else {
            gateFeature = feature
            return
        }

        switch feature {
        case .archives:
            viewModel.loadArchivedRoutines()
            showArchivesSheet = true
        case .nextRoutine:
            viewModel.loadUpcomingRoutines()
            showUpcomingRoutinesSheet = true
        case .advancedStats, .fullHistory, .advancedWidgets, .customization:
            showPaywall = true
        }
    }
}

private struct SettingsInfoSheet: View {
    let title: String
    let message: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(message)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                Color(hex: "FFF8F0")
                    .ignoresSafeArea()
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SettingsArchivesSheet: View {
    let items: [ArchivedRoutineSummary]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if items.isEmpty {
                        emptyState
                    } else {
                        ForEach(items) { item in
                            archiveCard(item)
                        }
                    }
                }
                .padding(Theme.padding)
                .padding(.bottom, 24)
            }
            .background(Theme.backgroundGradient(for: Theme.presets[6], scheme: colorScheme).ignoresSafeArea())
            .navigationTitle(L10n.text("settings.archives.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("settings.archives.empty.title"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(L10n.text("settings.archives.empty.message"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
        )
    }

    private func archiveCard(_ item: ArchivedRoutineSummary) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            ZStack {
                Circle()
                    .fill(Color(hex: item.colorHex).opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: item.iconSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: item.colorHex))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Text(item.periodText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))

                Text(item.detailsText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: item.colorHex))
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct SettingsUpcomingRoutinesSheet: View {
    let context: NSManagedObjectContext
    @ObservedObject var viewModel: SettingsViewModel
    let onActivateRoutine: (UUID) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var pendingActivation: UpcomingRoutineSummary?
    @State private var activatingRoutineID: UUID?
    @State private var showUpcomingRoutineSetup = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.upcomingRoutines.isEmpty {
                        emptyState
                    } else {
                        addButton

                        ForEach(viewModel.upcomingRoutines) { item in
                            upcomingCard(item)
                        }
                    }
                }
                .padding(Theme.padding)
                .padding(.bottom, 24)
            }
            .background(Theme.backgroundGradient(for: Theme.presets[6], scheme: colorScheme).ignoresSafeArea())
            .navigationTitle(L10n.text("settings.upcoming.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }

                if !viewModel.upcomingRoutines.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.text("settings.upcoming.add")) {
                            showUpcomingRoutineSetup = true
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showUpcomingRoutineSetup, onDismiss: {
            viewModel.loadUpcomingRoutines()
        }) {
            OnboardingView(
                context: context,
                mode: .upcoming
            ) {
                showUpcomingRoutineSetup = false
                viewModel.loadUpcomingRoutines()
            } onCancel: {
                showUpcomingRoutineSetup = false
                viewModel.loadUpcomingRoutines()
            }
        }
        .alert(
            L10n.text("settings.upcoming.switch.title"),
            isPresented: Binding(
                get: { pendingActivation != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingActivation = nil
                    }
                }
            ),
            presenting: pendingActivation
        ) { item in
            Button(L10n.text("settings.upcoming.switch.action")) {
                activatingRoutineID = item.id
                Task {
                    let didActivate = await onActivateRoutine(item.id)
                    activatingRoutineID = nil

                    if didActivate {
                        pendingActivation = nil
                        dismiss()
                    }
                }
            }
            Button(L10n.text("onboarding.cancel"), role: .cancel) {
                pendingActivation = nil
            }
        } message: { item in
            Text(
                String.localizedStringWithFormat(
                    L10n.text("settings.upcoming.switch.message"),
                    item.name
                )
            )
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("settings.upcoming.empty.title"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(L10n.text("settings.upcoming.empty.message"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Button(L10n.text("settings.upcoming.add")) {
                showUpcomingRoutineSetup = true
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Theme.accent)
            )
            .buttonStyle(.plain)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
        )
    }

    private var addButton: some View {
        Button(L10n.text("settings.upcoming.add")) {
            showUpcomingRoutineSetup = true
        }
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(Theme.accent)
        .buttonStyle(.plain)
    }

    private func upcomingCard(_ item: UpcomingRoutineSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingM) {
            HStack(alignment: .top, spacing: Theme.spacingM) {
                ZStack {
                    Circle()
                        .fill(Color(hex: item.colorHex).opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.iconSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: item.colorHex))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))

                    Text(item.remindersText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))

                    Text(item.dayStartText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: item.colorHex))
                }

                Spacer(minLength: 0)
            }

            Button {
                pendingActivation = item
            } label: {
                HStack {
                    if activatingRoutineID == item.id {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(L10n.text("settings.upcoming.switch"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: item.colorHex))
                )
            }
            .buttonStyle(.plain)
            .disabled(activatingRoutineID != nil)
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .environmentObject(StoreKitService())
    }
}
