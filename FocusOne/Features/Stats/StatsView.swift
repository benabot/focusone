import SwiftUI
import CoreData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel
    @Environment(\.colorScheme) private var cs
    @State private var appeared = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(context: context))
    }

    private var preset: ThemePreset { Theme.preset(for: viewModel.themeHex ?? Theme.defaultThemeHex) }

    // Mock data budget
    private let monthlyData: [(String, Double, Double)] = [
        ("Sep", 3200, 4100), ("Oct", 4800, 5200), ("Nov", 2900, 3800),
        ("Déc", 5100, 6000), ("Jan", 3700, 4500), ("Fév", 4200, 5800)
    ]
    private let categories: [(String, Double, String, String)] = [
        ("Outils & SaaS",  1240, "wrench.and.screwdriver.fill", "7C6FC4"),
        ("Sous-traitance", 3200, "person.2.fill",               "3A8FC4"),
        ("Infra",           580, "server.rack",                 "3DAA7D"),
        ("Marketing",       320, "megaphone.fill",              "F47D31"),
        ("Divers",          480, "ellipsis.circle.fill",        "D95B7E"),
    ]
    private var totalCat: Double { categories.reduce(0) { $0 + $1.1 } }

    var body: some View {
        ZStack {
            Color(hex: preset.softHex).ignoresSafeArea()
            VStack(spacing: 0) {
                statsHero
                contentArea
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            viewModel.load()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.1)) { appeared = true }
        }
    }

    // MARK: — Hero

    private var statsHero: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color(hex: preset.softHex)
                Circle().fill(Color(hex: preset.primaryHex).opacity(0.14))
                    .frame(width: 200, height: 200).offset(x: UIScreen.main.bounds.width - 80, y: 0)
                Circle().fill(Color.white.opacity(0.35)).frame(width: 80, height: 80)
                    .offset(x: UIScreen.main.bounds.width - 40, y: -50)
                MiniMascot(preset: preset).frame(width: 70, height: 70)
                    .offset(x: UIScreen.main.bounds.width - 110, y: -10)

                VStack(alignment: .leading, spacing: 6) {
                    Text("ANALYTICS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: preset.primaryHex)).kerning(1.8)
                    Text("Statistiques")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: preset.darkHex))
                    Text("6 derniers mois")
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

    // MARK: — Contenu

    private var contentArea: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Theme.card(cs)).ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: -3)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(Theme.fg2(cs).opacity(0.18)).frame(width: 36, height: 5).padding(.top, 12)
                    kpiRow
                    barChartCard
                    categoriesCard
                }
                .padding(.horizontal, Theme.pad)
                .padding(.bottom, 100)
            }
        }
        .frame(maxHeight: .infinity)
        .offset(y: appeared ? 0 : 50).opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: appeared)
    }

    // MARK: — KPI row

    private var kpiRow: some View {
        HStack(spacing: 12) {
            kpiTile(label: "CA total",    value: "21 400 €", icon: "eurosign.circle.fill", colorHex: "3DAA7D", primary: true)
            kpiTile(label: "Dépenses",    value: "5 820 €",  icon: "arrow.up.circle.fill",  colorHex: "E0654A", primary: false)
        }
    }

    private func kpiTile(label: String, value: String, icon: String, colorHex: String, primary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased()).font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(primary ? Color(hex: colorHex) : Theme.fg2(cs)).kerning(1.2)
                Spacer()
                Image(systemName: icon).font(.system(size: 11))
                    .foregroundStyle(Color(hex: colorHex).opacity(primary ? 1 : 0.5))
            }
            Text(value).font(.system(size: 32, weight: .black, design: .rounded)).foregroundStyle(Theme.fg(cs))
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
            .fill(primary ? Color(hex: colorHex).opacity(0.08) : Theme.surface(cs))
            .overlay(RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                .stroke(primary ? Color(hex: colorHex).opacity(0.15) : Color.clear, lineWidth: 1.5)))
    }

    // MARK: — Bar chart

    private var barChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("REVENUS VS DÉPENSES")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.fg2(cs)).kerning(1.4)

            let maxVal = monthlyData.map { max($0.1, $0.2) }.max() ?? 1
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(monthlyData, id: \.0) { item in
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 3) {
                            // Revenus
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(hex: "3DAA7D"))
                                .frame(width: 14, height: max(6, CGFloat(item.1 / maxVal) * 80))
                            // Dépenses
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color(hex: "E0654A").opacity(0.75))
                                .frame(width: 14, height: max(6, CGFloat(item.2 / maxVal) * 80))
                        }
                        Text(item.0).font(.system(size: 9, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110)

            // Légende
            HStack(spacing: 16) {
                legendDot(color: Color(hex: "3DAA7D"), label: "Revenus")
                legendDot(color: Color(hex: "E0654A").opacity(0.75), label: "Dépenses")
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.rL, style: .continuous).fill(Theme.surface(cs)))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
        }
    }

    // MARK: — Catégories

    private var categoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAR CATÉGORIE")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.fg2(cs)).kerning(1.4)

            ForEach(categories, id: \.0) { cat in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color(hex: cat.3).opacity(0.15)).frame(width: 34, height: 34)
                        Image(systemName: cat.2).font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: cat.3))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cat.0).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.fg(cs))
                            Spacer()
                            Text(cat.1.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.fg(cs))
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.card(cs)).frame(height: 5)
                                Capsule().fill(Color(hex: cat.3)).frame(width: g.size.width * CGFloat(cat.1 / totalCat), height: 5)
                            }
                        }.frame(height: 5)
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: Theme.rL, style: .continuous).fill(Theme.surface(cs)))
    }
}

// MARK: - Mini Mascot

private struct MiniMascot: View {
    let preset: ThemePreset
    @State private var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: preset.primaryHex))
                .shadow(color: Color(hex: preset.primaryHex).opacity(0.25), radius: 8, x: 0, y: 4)
            HStack(spacing: 10) {
                Circle().fill(Color.white).frame(width: 6, height: 6)
                Circle().fill(Color.white).frame(width: 6, height: 6)
            }.offset(y: -4)
            Capsule().fill(Color.white.opacity(0.85)).frame(width: 18, height: 4).offset(y: 8)
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { scale = 1.06 }
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView(context: PreviewSupport.context)
    }
}
