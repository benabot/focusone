import SwiftUI
import CoreData

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let mode: OnboardingMode
    let onFinished: () -> Void
    let onCancel: (() -> Void)?

    private let iconOptions = HabitIcon.availableSymbols

    init(context: NSManagedObjectContext,
         mode: OnboardingMode = .create,
         onFinished: @escaping () -> Void,
         onCancel: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(context: context, mode: mode))
        self.mode = mode
        self.onFinished = onFinished
        self.onCancel = onCancel
    }

    var body: some View {
        OnboardingContent(
            viewModel: viewModel,
            iconOptions: iconOptions,
            mode: mode,
            onFinished: onFinished,
            onCancel: onCancel
        )
    }
}

private struct OnboardingContent: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let iconOptions: [String]
    let mode: OnboardingMode
    let onFinished: () -> Void
    let onCancel: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isNameFocused: Bool
    @State private var showRemindersSheet = false
    @State private var showDayStartSheet = false

    private let iconColumns = Array(repeating: GridItem(.fixed(48), spacing: 12), count: 5)
    private let colorColumns = Array(repeating: GridItem(.fixed(36), spacing: 14), count: 6)

    private var displayedIconOptions: [String] {
        Array(iconOptions.prefix(10))
    }

    private var isNameValid: Bool {
        !trimmedHabitName.isEmpty
    }

    private var trimmedHabitName: String {
        viewModel.habitName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var previewName: String {
        trimmedHabitName.isEmpty
            ? L10n.text("onboarding.preview_name_placeholder")
            : trimmedHabitName
    }

    private var selectedPreset: ThemePreset {
        Theme.preset(for: viewModel.selectedThemeHex)
    }

    private var reminderSummary: String {
        guard viewModel.notificationsEnabled else {
            return L10n.text("onboarding.reminders.summary.none")
        }

        switch viewModel.reminderTimes.count {
        case 0:
            return L10n.text("onboarding.reminders.summary.none")
        case 1:
            return L10n.text("onboarding.reminders.summary.one")
        default:
            let format = L10n.text("onboarding.reminders.summary.many")
            return String.localizedStringWithFormat(format, viewModel.reminderTimes.count)
        }
    }

    private var titleText: String {
        mode == .edit ? L10n.text("onboarding.configuration") : L10n.text("onboarding.title")
    }

    private var subtitleText: String {
        mode == .edit ? L10n.text("onboarding.edit_subtitle") : L10n.text("onboarding.subtitle")
    }

    private var primaryActionTitle: String {
        mode == .edit ? L10n.text("onboarding.save") : L10n.text("onboarding.start")
    }

    private var cancelActionTitle: String? {
        onCancel == nil ? nil : L10n.text("onboarding.cancel")
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: selectedPreset, scheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacingL) {
                    header
                    previewCard
                    nameSection
                    iconSection
                    themeSection
                    preferencesSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.padding)
                .padding(.bottom, 132)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            ConfigurationFooterBar(
                primaryTitle: primaryActionTitle,
                secondaryTitle: cancelActionTitle,
                tintHex: viewModel.selectedThemeHex,
                isEnabled: isNameValid && !viewModel.isSaving,
                isLoading: viewModel.isSaving,
                errorMessage: viewModel.errorMessage,
                primaryAction: {
                    isNameFocused = false
                    Task {
                        if await viewModel.save() {
                            onFinished()
                        }
                    }
                },
                secondaryAction: {
                    onCancel?()
                }
            )
        }
        .sheet(isPresented: $showRemindersSheet) {
            RemindersSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDayStartSheet) {
            DayStartSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .onChange(of: viewModel.habitName) {
            if viewModel.errorMessage != nil {
                viewModel.errorMessage = nil
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleText)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(subtitleText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var previewCard: some View {
        RoutinePreviewCard(
            name: previewName,
            iconSymbol: viewModel.selectedIconSymbol,
            reminderSummary: reminderSummary,
            dayStartLabel: L10n.dayHourLabel(viewModel.dayStartHour),
            tintHex: viewModel.selectedThemeHex
        )
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            FormSectionTitle(title: L10n.text("onboarding.habit_section"))

            ConfigurationSurface(padding: 0) {
                TextField(L10n.text("onboarding.name_placeholder"), text: $viewModel.habitName)
                    .focused($isNameFocused)
                    .textInputAutocapitalization(.sentences)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            FormSectionTitle(title: L10n.text("onboarding.icon"))

            ConfigurationSurface {
                LazyVGrid(columns: iconColumns, alignment: .leading, spacing: 12) {
                    ForEach(displayedIconOptions, id: \.self) { symbol in
                        IconChip(
                            symbol: symbol,
                            isSelected: viewModel.selectedIconSymbol == symbol,
                            tintHex: viewModel.selectedThemeHex
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                                viewModel.selectedIconSymbol = symbol
                            }
                        }
                    }
                }
            }
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            FormSectionTitle(title: L10n.text("onboarding.theme"))

            ConfigurationSurface {
                LazyVGrid(columns: colorColumns, alignment: .leading, spacing: 14) {
                    ForEach(Theme.presets) { preset in
                        ColorDot(
                            hex: preset.primaryHex,
                            isSelected: viewModel.selectedThemeHex == preset.primaryHex
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.selectedThemeHex = preset.primaryHex
                            }
                        }
                        .accessibilityLabel(L10n.text(preset.nameKey))
                    }
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            FormSectionTitle(title: L10n.text("onboarding.preferences"))

            ConfigurationSurface(padding: 0) {
                VStack(spacing: 0) {
                    ConfigurationPreferenceRow(
                        title: L10n.text("onboarding.reminders"),
                        value: reminderSummary,
                        tintHex: viewModel.selectedThemeHex,
                        action: { showRemindersSheet = true }
                    )

                    sectionDivider

                    ConfigurationPreferenceRow(
                        title: L10n.text("onboarding.day_label"),
                        value: L10n.dayHourLabel(viewModel.dayStartHour),
                        tintHex: viewModel.selectedThemeHex,
                        action: { showDayStartSheet = true }
                    )
                }
            }
        }
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.75))
            .padding(.horizontal, 18)
    }
}

private struct FormSectionTitle: View {
    let title: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }
}

private struct ConfigurationSurface<Content: View>: View {
    let padding: CGFloat
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(padding: CGFloat = Theme.spacingM, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .fill(Theme.surface(for: colorScheme).opacity(colorScheme == .dark ? 0.94 : 0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.82), lineWidth: 1)
            )
    }
}

private struct RoutinePreviewCard: View {
    let name: String
    let iconSymbol: String
    let reminderSummary: String
    let dayStartLabel: String
    let tintHex: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ConfigurationSurface(padding: Theme.spacingM) {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: tintHex).opacity(colorScheme == .dark ? 0.22 : 0.16))
                            .frame(width: 56, height: 56)

                        Image(systemName: iconSymbol)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: tintHex))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary(for: colorScheme))
                            .lineLimit(2)

                        Text("\(reminderSummary) • \(dayStartLabel)")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Circle()
                        .fill(Color(hex: tintHex))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

private struct IconChip: View {
    let symbol: String
    let isSelected: Bool
    let tintHex: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(
                    isSelected
                        ? Color(hex: tintHex)
                        : Theme.textPrimary(for: colorScheme).opacity(0.72)
                )
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.78))
                )
                .overlay {
                    Circle()
                        .stroke(isSelected ? Color(hex: tintHex) : Color.clear, lineWidth: 2)
                }
                .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
    }
}

private struct ColorDot: View {
    let hex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 36, height: 36)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 46, height: 46)
            .overlay {
                if isSelected {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                            .frame(width: 40, height: 40)

                        Circle()
                            .stroke(Color(hex: hex).opacity(0.42), lineWidth: 2)
                            .frame(width: 46, height: 46)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.76), value: isSelected)
    }
}

private struct ConfigurationPreferenceRow: View {
    let title: String
    let value: String
    let tintHex: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingS) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                Spacer(minLength: Theme.spacingS)

                Text(value)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: tintHex).opacity(0.9))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ConfigurationFooterBar: View {
    let primaryTitle: String
    let secondaryTitle: String?
    let tintHex: String
    let isEnabled: Bool
    let isLoading: Bool
    let errorMessage: String?
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                if let secondaryTitle {
                    Button(secondaryTitle, action: secondaryAction)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                        .frame(width: 118)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Theme.surface(for: colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8), lineWidth: 1)
                        )
                        .buttonStyle(.plain)
                }

                Button(action: primaryAction) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(isEnabled ? .white : Theme.textSecondary(for: colorScheme))
                        }

                        Text(primaryTitle)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(primaryBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(primaryBorderColor, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
            }
        }
        .padding(.horizontal, Theme.padding)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            Theme.surface(for: colorScheme)
                .opacity(colorScheme == .dark ? 0.98 : 0.96)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Divider()
                .overlay(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.8))
        }
    }

    private var primaryTextColor: Color {
        isEnabled ? .white : Theme.textSecondary(for: colorScheme)
    }

    private var primaryBackgroundColor: Color {
        isEnabled ? Color(hex: tintHex) : Color.white.opacity(colorScheme == .dark ? 0.12 : 0.82)
    }

    private var primaryBorderColor: Color {
        isEnabled ? Color.clear : Color(hex: tintHex).opacity(0.16)
    }
}

private struct RemindersSheet: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Toggle(L10n.text("settings.notifications"), isOn: $viewModel.notificationsEnabled)
                        .tint(Color(hex: viewModel.selectedThemeHex))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))

                    if viewModel.notificationsEnabled {
                        ForEach(viewModel.reminderTimes.indices, id: \.self) { index in
                            HStack(spacing: 12) {
                                DatePicker(
                                    L10n.text("onboarding.reminder"),
                                    selection: Binding(
                                        get: { viewModel.reminderTimes[index] },
                                        set: { viewModel.reminderTimes[index] = $0 }
                                    ),
                                    displayedComponents: [.hourAndMinute]
                                )
                                .labelsHidden()

                                Spacer()

                                Button(L10n.text("common.remove")) {
                                    viewModel.removeReminder(at: index)
                                }
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(hex: viewModel.selectedThemeHex))
                            }
                        }

                        if viewModel.reminderTimes.count < 2 {
                            Button {
                                viewModel.addReminder()
                            } label: {
                                Label(L10n.text("onboarding.add_reminder"), systemImage: "plus")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(hex: viewModel.selectedThemeHex))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(L10n.text("onboarding.reminders"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
            .background(
                Color(hex: "FFF8F0")
                    .ignoresSafeArea()
            )
        }
    }
}

private struct DayStartSheet: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

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
                    L10n.text("onboarding.day_start"),
                    selection: dayStartBinding,
                    displayedComponents: [.hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Text(L10n.dayHourLabel(viewModel.dayStartHour))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: viewModel.selectedThemeHex))

                Spacer()
            }
            .padding(20)
            .navigationTitle(L10n.text("onboarding.day_start"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("common.close")) {
                        dismiss()
                    }
                }
            }
            .background(
                Color(hex: "FFF8F0")
                    .ignoresSafeArea()
            )
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(context: PreviewSupport.context, onFinished: {})
    }
}
