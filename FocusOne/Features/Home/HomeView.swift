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
                VStack(alignment: .leading, spacing: 18) {
                    if let habit = viewModel.habit {
                        topBar(habit: habit, preset: preset)
                        heroCard(habit: habit, preset: preset)
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

    private func heroCard(habit: Habit, preset: ThemePreset) -> some View {
        HomeHeroCard(
            accentHex: preset.primaryHex,
            streakCount: viewModel.currentStreak,
            streakUnit: L10n.streakUnit(viewModel.currentStreak),
            supportText: viewModel.todayStatusText,
            todayValue: viewModel.todayStatusShort,
            bestValue: viewModel.bestStreakText,
            reminderText: viewModel.nextReminderText,
            primaryTitle: viewModel.doneToday
                ? L10n.text("home.done.button.on")
                : L10n.text("home.done.button.off"),
            isDoneToday: viewModel.doneToday
        ) {
            viewModel.toggleDoneToday()
        }
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

private struct HomeHeroCard: View {
    let accentHex: String
    let streakCount: Int
    let streakUnit: String
    let supportText: String
    let todayValue: String
    let bestValue: String
    let reminderText: String
    let primaryTitle: String
    let isDoneToday: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            streakHeader
            supportLine
            metricsRow
            reminderRow
            primaryButton
        }
        .padding(24)
        .background(backgroundCard)
        .overlay(cardOutline)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var streakHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("home.streak.label").uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: accentHex).opacity(0.84))
                .kerning(0.8)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(streakCount)")
                    .font(.system(size: 82, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())

                Text(streakUnit)
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                    .padding(.bottom, 12)
            }
        }
    }

    private var supportLine: some View {
        Text(supportText)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(Theme.textSecondary(for: colorScheme))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            metricCard(
                title: L10n.text("home.today.label"),
                value: todayValue,
                valueColor: isDoneToday ? Color(hex: "48A16C") : Theme.textPrimary(for: colorScheme)
            )

            metricCard(
                title: L10n.text("home.best_streak"),
                value: bestValue,
                valueColor: Theme.textPrimary(for: colorScheme)
            )
        }
    }

    private func metricCard(title: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .textCase(.uppercase)
                .kerning(0.5)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.62))
        )
    }

    private var reminderRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(reminderText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(Theme.textSecondary(for: colorScheme))
    }

    private var primaryButton: some View {
        Button(action: action) {
            Text(primaryTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(isDoneToday ? Theme.textSecondary(for: colorScheme) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            isDoneToday
                                ? Color.white.opacity(colorScheme == .dark ? 0.12 : 0.75)
                                : Color(hex: accentHex)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            isDoneToday ? Color(hex: accentHex).opacity(0.16) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(isDoneToday)
    }

    private var backgroundCard: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: accentHex).opacity(0.28), Color(hex: accentHex).opacity(0.12)]
                        : [Color(hex: accentHex).opacity(0.22), Color.white.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color(hex: accentHex).opacity(0.10))
                    .frame(width: 116, height: 116)
                    .blur(radius: 12)
                    .offset(x: 24, y: -18)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(Color(hex: accentHex).opacity(0.08))
                    .frame(width: 148, height: 148)
                    .blur(radius: 18)
                    .offset(x: -36, y: 52)
            }
    }

    private var cardOutline: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(Color(hex: accentHex).opacity(colorScheme == .dark ? 0.2 : 0.14), lineWidth: 1)
    }
}
