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

    private let iconColumns = Array(repeating: GridItem(.fixed(44), spacing: 12), count: 5)
    private let colorColumns = Array(repeating: GridItem(.fixed(30), spacing: 14), count: 6)

    private var displayedIconOptions: [String] {
        Array(iconOptions.prefix(12))
    }

    private var isNameValid: Bool {
        !viewModel.habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    private var subtitleSecondary: String {
        let key = mode == .edit ? "onboarding.edit_subtitle_secondary" : "onboarding.subtitle_secondary"
        return L10n.text(key).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var titleText: String {
        mode == .edit ? L10n.text("onboarding.configuration") : L10n.text("onboarding.title")
    }

    private var subtitleText: String {
        mode == .edit ? L10n.text("onboarding.edit_subtitle") : L10n.text("onboarding.subtitle")
    }

    private var primaryActionTitle: String {
        mode == .edit ? L10n.text("onboarding.save") : L10n.text("common.cta.start")
    }

    private var cancelActionTitle: String? {
        mode == .edit ? L10n.text("onboarding.cancel") : nil
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FFECDD"), Color(hex: "FFF7EE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    nameSection
                    iconSection
                    themeSection
                    preferencesSection

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            BottomCTAContainer(
                primaryTitle: primaryActionTitle,
                secondaryTitle: cancelActionTitle,
                tintHex: viewModel.selectedThemeHex,
                isEnabled: isNameValid && !viewModel.isSaving,
                isLoading: viewModel.isSaving,
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Text(subtitleText)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            if !subtitleSecondary.isEmpty {
                Text(subtitleSecondary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme).opacity(0.85))
                    .lineLimit(1)
            }

            OnboardingBlob()
                .frame(width: 128, height: 80)
                .padding(.top, 4)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: L10n.text("onboarding.habit_section"))

            TextField(L10n.text("onboarding.name_placeholder"), text: $viewModel.habitName)
                .focused($isNameFocused)
                .textInputAutocapitalization(.sentences)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.74))
                )
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L10n.text("onboarding.icon"))

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

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L10n.text("onboarding.theme"))

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

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L10n.text("onboarding.preferences"))

            CollapsedRow(
                title: L10n.text("onboarding.reminders"),
                value: reminderSummary,
                actionTitle: L10n.text("onboarding.manage"),
                tintHex: viewModel.selectedThemeHex,
                action: { showRemindersSheet = true }
            )

            CollapsedRow(
                title: L10n.text("onboarding.day_label"),
                value: L10n.dayHourLabel(viewModel.dayStartHour),
                actionTitle: L10n.text("onboarding.manage"),
                tintHex: viewModel.selectedThemeHex,
                action: { showDayStartSheet = true }
            )
        }
    }
}

private struct SectionHeader: View {
    let title: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }
}

private struct OnboardingBlob: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .frame(width: 122, height: 72)
                .rotationEffect(.degrees(-8))

            Circle()
                .fill(Color(hex: "FFD9C9").opacity(0.9))
                .frame(width: 56, height: 56)
                .offset(x: -22, y: -8)

            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 42, height: 42)
                .offset(x: 28, y: 10)

            Capsule()
                .fill(Color(hex: "FFB76B").opacity(0.46))
                .frame(width: 56, height: 16)
                .offset(x: 8, y: 24)
        }
        .accessibilityHidden(true)
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    isSelected
                        ? Color(hex: tintHex)
                        : Theme.textPrimary(for: colorScheme).opacity(0.7)
                )
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.24 : 0.68))
                )
                .overlay {
                    Circle()
                        .stroke(isSelected ? Color(hex: tintHex) : Color.clear, lineWidth: 2)
                }
                .scaleEffect(isSelected ? 1.07 : 1)
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
                    .frame(width: 30, height: 30)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 42, height: 42)
            .overlay {
                if isSelected {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(Color(hex: hex).opacity(0.45), lineWidth: 2)
                            .frame(width: 42, height: 42)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.76), value: isSelected)
    }
}

private struct CollapsedRow: View {
    let title: String
    let value: String
    let actionTitle: String
    let tintHex: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            Spacer()

            Text(value)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))

            Button(actionTitle, action: action)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: tintHex))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.64))
                .clipShape(Capsule())
                .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

private struct BottomCTAContainer: View {
    let primaryTitle: String
    let secondaryTitle: String?
    let tintHex: String
    let isEnabled: Bool
    let isLoading: Bool
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .tint(.secondary)
            }

            if let secondaryTitle {
                Button(secondaryTitle, action: secondaryAction)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }

            Button(action: primaryAction) {
                Text(primaryTitle)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            Color(hex: "FFF8F0")
                .opacity(0.94)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var primaryTextColor: Color {
        isEnabled ? .white : Theme.textSecondary(for: colorScheme)
    }

    private var primaryBackgroundColor: Color {
        isEnabled ? Color(hex: tintHex) : Color.white.opacity(colorScheme == .dark ? 0.14 : 0.82)
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
