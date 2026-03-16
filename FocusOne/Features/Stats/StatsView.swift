import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showPaywall = false
    @State private var showFullHistory = false
    @State private var gateFeature: PremiumFeature?

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: context))
    }

    private var preset: ThemePreset {
        Theme.preset(for: viewModel.themeHex ?? Theme.defaultThemeHex)
    }

    private var accentColor: Color {
        Color(hex: preset.primaryHex)
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: preset, scheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    header

                    if viewModel.habitIconSymbol == nil {
                        emptyState
                    } else {
                        metricsGrid
                        monthSection
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: viewModel.load)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showFullHistory) {
            StatsFullHistorySheet(
                months: viewModel.historyMonths,
                preset: preset
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.text("stats.title"))
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary(for: colorScheme))

            if let symbol = viewModel.habitIconSymbol {
                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accentColor)

                    Text(L10n.text("home.title"))
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textSecondary(for: colorScheme))
                }
            }
        }
    }

    private var emptyState: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("stats.title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary(for: colorScheme))

                Text(L10n.text("home.no_habit"))
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textSecondary(for: colorScheme))
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            primaryCurrentCard
                .gridCellColumns(2)

            secondaryMetricCard(
                title: L10n.text("stats.best"),
                value: L10n.streakDays(viewModel.bestStreak),
                accent: false
            )

            secondaryMetricCard(
                title: L10n.text("stats.last7"),
                value: L10n.completionPercent(viewModel.completionRate7),
                accent: false
            )

            secondaryMetricCard(
                title: L10n.text("stats.last30"),
                value: L10n.completionPercent(viewModel.completionRate30),
                accent: true
            )
            .gridCellColumns(2)
        }
    }

    private var primaryCurrentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("stats.current").uppercased())
                .font(AppTypography.overline)
                .foregroundStyle(accentColor.opacity(0.9))
                .kerning(0.8)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary(for: colorScheme))
                    .contentTransition(.numericText())

                Text(L10n.streakUnit(viewModel.currentStreak))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary(for: colorScheme))
                    .padding(.bottom, 10)
            }

            Text(L10n.streakInARowLabel(viewModel.currentStreak))
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textSecondary(for: colorScheme))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(colorScheme == .dark ? 0.28 : 0.22),
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.86)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accentColor.opacity(colorScheme == .dark ? 0.18 : 0.14), lineWidth: 1)
        )
    }

    private func secondaryMetricCard(title: String, value: String, accent: Bool) -> some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppTypography.overline)
                    .foregroundStyle(accent ? accentColor.opacity(0.88) : AppColors.textSecondary(for: colorScheme))
                    .kerning(0.6)

                Text(value)
                    .font(AppTypography.cardValue)
                    .foregroundStyle(AppColors.textPrimary(for: colorScheme))
            }
        }
    }

    private var monthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionTitle(title: viewModel.monthTitle.capitalized)

            AppSurface {
                VStack(alignment: .leading, spacing: 16) {
                    MonthGrid(days: viewModel.monthDays, preset: preset, colorScheme: colorScheme)

                    Button(action: openFullHistory) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.text("stats.full_history"))
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary(for: colorScheme))

                                Text(L10n.text("stats.full_history.caption"))
                                    .font(AppTypography.bodySmall)
                                    .foregroundStyle(Theme.textSecondary(for: colorScheme))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func openFullHistory() {
        let gate = PremiumGate()

        if gate.canAccess(.fullHistory) {
            showFullHistory = true
        } else {
            gateFeature = .fullHistory
        }
    }
}

private struct MonthGrid: View {
    let days: [MonthGridDay]
    let preset: ThemePreset
    let colorScheme: ColorScheme

    private let weekLetters = ["L", "M", "M", "J", "V", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekLetters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme).opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days) { day in
                    dayCell(day)
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: MonthGridDay) -> some View {
        let textColor: Color = {
            if !day.isCurrentMonth { return Theme.textSecondary(for: colorScheme).opacity(0.25) }
            if day.isCompleted { return .white }
            return Theme.textPrimary(for: colorScheme)
        }()

        let background: Color = {
            if day.isCompleted { return Color(hex: preset.primaryHex) }
            if day.isCurrentMonth { return Color.white.opacity(colorScheme == .dark ? 0.07 : 0.35) }
            return .clear
        }()

        Text("\(day.dayNumber)")
            .font(.system(size: 13, weight: day.isCompleted ? .bold : .regular, design: .rounded))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(background)
                    .shadow(
                        color: day.isCompleted ? Color(hex: preset.primaryHex).opacity(0.35) : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(context: PreviewSupport.context)
    }
}

private struct StatsFullHistorySheet: View {
    let months: [HistoryMonthSection]
    let preset: ThemePreset

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.l) {
                    if months.isEmpty {
                        AppSurface {
                            Text(L10n.text("stats.full_history.empty"))
                                .font(AppTypography.bodySmall)
                                .foregroundStyle(AppColors.textSecondary(for: colorScheme))
                        }
                    } else {
                        ForEach(months) { month in
                            VStack(alignment: .leading, spacing: 12) {
                                AppSectionTitle(title: month.title)

                                AppSurface {
                                    MonthGrid(days: month.days, preset: preset, colorScheme: colorScheme)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.padding)
                .padding(.bottom, 24)
            }
            .background(Theme.backgroundGradient(for: preset, scheme: colorScheme).ignoresSafeArea())
            .navigationTitle(L10n.text("stats.full_history"))
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
