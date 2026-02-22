import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: context))
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient(for: Theme.presets[3], scheme: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    header
                    streakHero
                    ratesRow
                    monthSection
                }
                .padding(Theme.padding)
            }
        }
        .onAppear(perform: viewModel.load)
    }

    private var header: some View {
        HStack(spacing: Theme.spacingS) {
            if let symbol = viewModel.habitIconSymbol {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
            }

            Text(L10n.text("stats.title"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))
        }
    }

    private var streakHero: some View {
        HStack(spacing: Theme.spacingM) {
            streakMetric(
                title: L10n.text("stats.current"),
                value: "\(viewModel.currentStreak)",
                tone: Theme.textPrimary(for: colorScheme)
            )

            streakMetric(
                title: L10n.text("stats.best"),
                value: "\(viewModel.bestStreak)",
                tone: Theme.textSecondary(for: colorScheme)
            )
        }
    }

    private var ratesRow: some View {
        HStack(spacing: Theme.spacingS) {
            ratePill(title: L10n.text("stats.last7"), value: L10n.completionPercent(viewModel.completionRate7))
            ratePill(title: L10n.text("stats.last30"), value: L10n.completionPercent(viewModel.completionRate30))
        }
    }

    private var monthSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text(viewModel.monthTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            MonthGrid(days: viewModel.monthDays, colorScheme: colorScheme)
        }
    }

    private func streakMetric(title: String, value: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))

            Text(value)
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(tone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ratePill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))
        }
        .padding(.horizontal, Theme.spacingM)
        .padding(.vertical, Theme.spacingS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.62))
        )
    }
}

private struct MonthGrid: View {
    let days: [MonthGridDay]
    let colorScheme: ColorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days) { day in
                Text("\(day.dayNumber)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        day.isCurrentMonth
                            ? Theme.textPrimary(for: colorScheme)
                            : Theme.textSecondary(for: colorScheme).opacity(0.4)
                    )
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                day.isCompleted
                                    ? Color(hex: Theme.defaultThemeHex).opacity(0.92)
                                    : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.42)
                            )
                    )
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(context: PreviewSupport.context)
    }
}
