import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEditConfiguration = false
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }

    var body: some View {
        let preset = Theme.preset(for: viewModel.habit?.colorHex ?? Theme.defaultThemeHex)

        ZStack(alignment: .top) {
            Theme.backgroundGradient(for: preset, scheme: colorScheme).ignoresSafeArea()

            topBlob(for: preset)
                .frame(height: 170)
                .padding(.top, -24)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    if let habit = viewModel.habit {
                        topHeader(habit: habit, preset: preset)
                        streakBlock
                        statusRow
                        reminderRow

                        DoneToggleButton(isDone: viewModel.doneToday, tintHex: preset.primaryHex) {
                            viewModel.toggleDoneToday()
                        }
                        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: viewModel.doneToday)
                    } else {
                        Text(L10n.text("home.no_habit"))
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary(for: colorScheme))
                            .padding(.top, Theme.spacing)
                    }
                }
                .padding(Theme.padding)
            }
        }
        .onAppear(perform: viewModel.load)
        .sheet(isPresented: $showEditConfiguration, onDismiss: {
            viewModel.load()
        }) {
            OnboardingView(
                context: context,
                mode: .edit,
                onFinished: {
                    showEditConfiguration = false
                    viewModel.load()
                },
                onCancel: {
                    showEditConfiguration = false
                }
            )
            .presentationDetents([.large])
        }
    }

    private func topHeader(habit: Habit, preset: ThemePreset) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingM) {
            topIdentity(habit: habit, preset: preset)

            Spacer()

            Button(L10n.text("home.edit")) {
                showEditConfiguration = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color(hex: preset.primaryHex))
            .padding(.horizontal, Theme.spacingS)
            .padding(.vertical, 8)
            .background(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.64))
            .clipShape(Capsule())
            .buttonStyle(.plain)
        }
    }

    private func topIdentity(habit: Habit, preset: ThemePreset) -> some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: habit.iconSymbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color(hex: preset.primaryHex))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.7))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text("home.title"))
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))

                Text(habit.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
            }
        }
    }

    private var streakBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(viewModel.currentStreak)")
                .font(.system(size: 88, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(L10n.streakInARowLabel(viewModel.currentStreak))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
        }
    }

    private var statusRow: some View {
        HStack(spacing: Theme.spacingS) {
            Text(L10n.text("home.today.label"))
            Text(viewModel.todayStatusShort)
                .fontWeight(.semibold)
            Spacer()
            Text("\(L10n.text("home.best.short")): \(viewModel.bestStreak)")
        }
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }

    private var reminderRow: some View {
        HStack(spacing: Theme.spacingXS) {
            Image(systemName: "bell.fill")
            Text(viewModel.nextReminderText)
        }
        .font(.footnote)
        .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }

    private func topBlob(for preset: ThemePreset) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.16))
                .frame(width: 190, height: 190)
                .offset(x: -104, y: -52)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white.opacity(0.4))
                .frame(width: 170, height: 90)
                .offset(x: 102, y: -28)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(context: PreviewSupport.context)
    }
}
