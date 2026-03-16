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
            Theme.backgroundGradient(for: preset, scheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let habit = viewModel.habit {
                        topBar(habit: habit, preset: preset)
                        streakCard(preset: preset)
                        metaRow
                        reminderChip
                        Spacer(minLength: 4)
                        doneButton(preset: preset)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: viewModel.load)
        .sheet(isPresented: $showEditConfiguration, onDismiss: viewModel.load) {
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

    // MARK: — Top bar

    private func topBar(habit: Habit, preset: ThemePreset) -> some View {
        HStack(alignment: .center, spacing: Theme.spacingS) {
            // Icon + name
            HStack(spacing: Theme.spacingS) {
                ZStack {
                    Circle()
                        .fill(Color(hex: preset.primaryHex).opacity(colorScheme == .dark ? 0.25 : 0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: habit.iconSymbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: preset.primaryHex))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.text("home.title").uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                        .kerning(0.5)
                    Text(habit.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                showEditConfiguration = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.55))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: — Streak card

    private func streakCard(preset: ThemePreset) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(hex: preset.primaryHex).opacity(0.28), Color(hex: preset.primaryHex).opacity(0.12)]
                            : [Color(hex: preset.primaryHex).opacity(0.18), Color(hex: preset.softHex).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(hex: preset.primaryHex).opacity(colorScheme == .dark ? 0.2 : 0.12), lineWidth: 1)
                )

            // Decorative blobs
            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: -30, y: 40)
                .blur(radius: 20)
                .allowsHitTesting(false)

            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.08))
                .frame(width: 90, height: 90)
                .offset(x: 260, y: -30)
                .blur(radius: 16)
                .allowsHitTesting(false)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.text("home.streak.label").uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: preset.primaryHex).opacity(0.8))
                    .kerning(0.8)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.textPrimary(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.currentStreak)

                    Text(L10n.streakUnit(viewModel.currentStreak))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                        .padding(.bottom, 10)
                }

                if viewModel.currentStreak > 0 {
                    Text(L10n.text("home.streak.keep_going"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme))
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .bottomLeading)
        .clipped()
    }

    // MARK: — Meta row (today + best)

    private var metaRow: some View {
        HStack(spacing: 12) {
            metaPill(
                icon: "calendar",
                label: L10n.text("home.today.label"),
                value: viewModel.todayStatusShort
            )
            metaPill(
                icon: "trophy.fill",
                label: L10n.text("home.best.short"),
                value: "\(viewModel.bestStreak)"
            )
        }
    }

    private func metaPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .textCase(.uppercase)
                    .kerning(0.3)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5))
        )
    }

    // MARK: — Reminder chip

    private var reminderChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(viewModel.nextReminderText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Theme.textSecondary(for: colorScheme))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.45))
        )
    }

    // MARK: — Done button

    private func doneButton(preset: ThemePreset) -> some View {
        DoneToggleButton(isDone: viewModel.doneToday, tintHex: preset.primaryHex) {
            viewModel.toggleDoneToday()
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: viewModel.doneToday)
    }

    // MARK: — Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
            Text(L10n.text("home.no_habit"))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(context: PreviewSupport.context)
    }
}
