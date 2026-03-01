import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    @Environment(\.colorScheme) private var cs
    @State private var appeared = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: context))
    }

    private var preset: ThemePreset {
        Theme.preset(for: viewModel.themeHex ?? Theme.defaultThemeHex)
    }

    var body: some View {
        ZStack {
            // Fond crème Headspace
            Color(hex: preset.softHex).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    statsHero
                    contentArea
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            viewModel.load()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: — Hero

    private var statsHero: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color(hex: preset.softHex)

                // Décorations organiques
                Circle()
                    .fill(Color(hex: preset.primaryHex).opacity(0.14))
                    .frame(width: 200, height: 200)
                    .offset(x: UIScreen.main.bounds.width - 80, y: 0)

                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 80, height: 80)
                    .offset(x: UIScreen.main.bounds.width - 40, y: -50)

                // Petit mascot réduit
                MiniMascot(preset: preset)
                    .frame(width: 70, height: 70)
                    .offset(x: UIScreen.main.bounds.width - 110, y: -10)

                // Texte
                VStack(alignment: .leading, spacing: 6) {
                    if let sym = viewModel.habitIconSymbol {
                        ZStack {
                            Circle()
                                .fill(Color(hex: preset.primaryHex).opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: sym)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: preset.primaryHex))
                        }
                        .padding(.bottom, 4)
                    }

                    Text(L10n.text("stats.title"))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: preset.darkHex))

                    Text(L10n.text("stats.hero.subtitle"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: preset.darkHex).opacity(0.5))
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, Theme.pad)
                .padding(.top, geo.safeAreaInsets.top + 16)
            }
        }
        .frame(height: 200)
    }

    // MARK: — Contenu sur fond blanc

    private var contentArea: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Theme.card(cs))
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: -3)

            VStack(spacing: 14) {
                // Handle
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Theme.fg2(cs).opacity(0.18))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                streakRow
                ratesRow
                calendarCard
                    .padding(.bottom, 34)
            }
            .padding(.horizontal, Theme.pad)
        }
        .offset(y: appeared ? 0 : 50)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: — Streak row

    private var streakRow: some View {
        HStack(spacing: 12) {
            streakTile(
                label: L10n.text("stats.current"),
                value: viewModel.currentStreak,
                icon: "flame.fill",
                primary: true
            )
            streakTile(
                label: L10n.text("stats.best"),
                value: viewModel.bestStreak,
                icon: "trophy.fill",
                primary: false
            )
        }
    }

    private func streakTile(label: String, value: Int, icon: String, primary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(primary
                                     ? Color(hex: preset.primaryHex)
                                     : Theme.fg2(cs))
                    .kerning(1.2)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(primary
                                     ? Color(hex: preset.primaryHex)
                                     : Theme.fg2(cs).opacity(0.4))
            }

            Text("\(value)")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(Theme.fg(cs))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)

            Text(L10n.streakUnit(value))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.fg2(cs))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                .fill(primary
                      ? Color(hex: preset.primaryHex).opacity(0.08)
                      : Theme.surface(cs))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                .stroke(primary
                        ? Color(hex: preset.primaryHex).opacity(0.15)
                        : Color.clear,
                        lineWidth: 1.5)
        )
    }

    // MARK: — Rates row

    private var ratesRow: some View {
        HStack(spacing: 12) {
            rateTile(label: L10n.text("stats.last7"),  value: viewModel.completionRate7)
            rateTile(label: L10n.text("stats.last30"), value: viewModel.completionRate30)
        }
    }

    private func rateTile(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.fg2(cs))
                .kerning(1.2)

            HStack(spacing: 14) {
                // Arc circulaire
                ZStack {
                    Circle()
                        .stroke(Theme.surface(cs), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    Circle()
                        .trim(from: 0, to: CGFloat(value))
                        .stroke(Color(hex: preset.primaryHex),
                                style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: value)
                    Text(L10n.completionPercent(value))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.fg(cs))
                }
                .frame(width: 54, height: 54)

                Text(value >= 0.8 ? "🌟" : value >= 0.5 ? "👍" : "💪")
                    .font(.system(size: 26))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                .fill(Theme.surface(cs))
        )
    }

    // MARK: — Calendar card

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(viewModel.monthTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.fg(cs))
                Spacer()
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(hex: preset.primaryHex))
                        .frame(width: 10, height: 10)
                    Text(L10n.text("stats.legend.done"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.fg2(cs))
                }
            }
            CalendarGrid(days: viewModel.monthDays, preset: preset, cs: cs)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                .fill(Theme.surface(cs))
        )
    }
}

// MARK: - Calendar grid

private struct CalendarGrid: View {
    let days: [MonthGridDay]
    let preset: ThemePreset
    let cs: ColorScheme

    private let letters = ["L","M","M","J","V","S","D"]
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(letters, id: \.self) { l in
                    Text(l)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.fg2(cs).opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: cols, spacing: 5) {
                ForEach(days) { day in cellView(day) }
            }
        }
    }

    @ViewBuilder
    private func cellView(_ day: MonthGridDay) -> some View {
        let isCompleted = day.isCompleted
        let inMonth = day.isCurrentMonth

        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    isCompleted
                        ? Color(hex: preset.primaryHex)
                        : (inMonth ? Theme.card(cs) : Color.clear)
                )

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.white)
            } else {
                Text("\(day.dayNumber)")
                    .font(.system(size: 12, weight: inMonth ? .medium : .regular, design: .rounded))
                    .foregroundStyle(
                        inMonth ? Theme.fg(cs) : Theme.fg2(cs).opacity(0.2)
                    )
            }
        }
        .frame(height: 32)
        .shadow(
            color: isCompleted ? Color(hex: preset.primaryHex).opacity(0.28) : .clear,
            radius: 4, x: 0, y: 2
        )
    }
}

// MARK: - Mini mascot pour la hero stats

private struct MiniMascot: View {
    let preset: ThemePreset
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: preset.primaryHex))
                .shadow(color: Color(hex: preset.primaryHex).opacity(0.25), radius: 8, x: 0, y: 4)

            HStack(spacing: 10) {
                Circle().fill(Color.white).frame(width: 6, height: 6)
                Circle().fill(Color.white).frame(width: 6, height: 6)
            }
            .offset(y: -4)

            Capsule()
                .fill(Color.white.opacity(0.85))
                .frame(width: 18, height: 4)
                .offset(y: 8)
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                scale = 1.06
            }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(context: PreviewSupport.context)
    }
}
