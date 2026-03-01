import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: context))
    }

    var body: some View {
        let preset = Theme.preset(for: viewModel.themeHex ?? Theme.defaultThemeHex)

        ZStack {
            Theme.backgroundGradient(for: preset, scheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    streakCards(preset: preset)
                    ratesRow(preset: preset)
                    monthSection(preset: preset)
                }
                .padding(.horizontal, Theme.padding)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: viewModel.load)
    }

    // MARK: — Header

    private var header: some View {
        HStack(spacing: Theme.spacingS) {
            if let symbol = viewModel.habitIconSymbol {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary(for: colorScheme))
            }
            Text(L10n.text("stats.title"))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))
        }
    }

    // MARK: — Streak cards side-by-side

    private func streakCards(preset: ThemePreset) -> some View {
        HStack(spacing: 12) {
            streakCard(
                title: L10n.text("stats.current"),
                value: viewModel.currentStreak,
                isPrimary: true,
                preset: preset
            )
            streakCard(
                title: L10n.text("stats.best"),
                value: viewModel.bestStreak,
                isPrimary: false,
                preset: preset
            )
        }
    }

    private func streakCard(title: String, value: Int, isPrimary: Bool, preset: ThemePreset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isPrimary
                        ? Color(hex: preset.primaryHex).opacity(0.8)
                        : Theme.textSecondary(for: colorScheme)
                )
                .textCase(.uppercase)
                .kerning(0.5)

            Text("\(value)")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    isPrimary
                        ? Theme.textPrimary(for: colorScheme)
                        : Theme.textSecondary(for: colorScheme)
                )
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    isPrimary
                        ? Color(hex: preset.primaryHex).opacity(colorScheme == .dark ? 0.22 : 0.13)
                        : Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isPrimary
                        ? Color(hex: preset.primaryHex).opacity(colorScheme == .dark ? 0.2 : 0.1)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }

    // MARK: — Rates

    private func ratesRow(preset: ThemePreset) -> some View {
        HStack(spacing: 12) {
            ratePill(
                title: L10n.text("stats.last7"),
                value: L10n.completionPercent(viewModel.completionRate7),
                preset: preset
            )
            ratePill(
                title: L10n.text("stats.last30"),
                value: L10n.completionPercent(viewModel.completionRate30),
                preset: preset
            )
        }
    }

    private func ratePill(title: String, value: String, preset: ThemePreset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textSecondary(for: colorScheme))
                .textCase(.uppercase)
                .kerning(0.4)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5))
        )
    }

    // MARK: — Month grid

    private func monthSection(preset: ThemePreset) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.monthTitle)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary(for: colorScheme))

            MonthGrid(days: viewModel.monthDays, preset: preset, colorScheme: colorScheme)
        }
    }
}

// MARK: — Month grid component

private struct MonthGrid: View {
    let days: [MonthGridDay]
    let preset: ThemePreset
    let colorScheme: ColorScheme

    private let weekLetters = ["L", "M", "M", "J", "V", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekLetters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary(for: colorScheme).opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days) { day in
                    dayCell(day)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.07 : 0.45))
        )
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
                        radius: 4, x: 0, y: 2
                    )
            )
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(context: PreviewSupport.context)
    }
}
