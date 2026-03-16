import SwiftUI
import CoreData

// MARK: - HomeView — Dashboard Budget

struct HomeView: View {
    @Environment(\.colorScheme) private var cs
    @State private var appeared = false
    private let context: NSManagedObjectContext

    private let totalBudget: Double = 12_400
    private let totalSpent: Double  = 7_820
    private let totalIncome: Double = 9_200
    private let recentTx: [MockTx] = MockTx.samples

    private var remaining: Double  { totalBudget - totalSpent }
    private var spentRatio: Double { min(totalSpent / totalBudget, 1.0) }
    private var preset: ThemePreset { Theme.preset(for: Theme.defaultThemeHex) }

    init(context: NSManagedObjectContext) { self.context = context }

    var body: some View {
        ZStack {
            Color(hex: preset.softHex).ignoresSafeArea()
            VStack(spacing: 0) {
                topArea
                bottomSheet
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.1)) { appeared = true }
        }
    }

    // MARK: — Top hero

    private var topArea: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color(hex: preset.softHex)
                decorCircles
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BUDGET")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(hex: preset.primaryHex)).kerning(1.8)
                            Text("Vue d'ensemble")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: preset.darkHex))
                        }
                        Spacer()
                        Button {} label: {
                            Circle().fill(Color.white.opacity(0.55)).frame(width: 40, height: 40)
                                .overlay(Image(systemName: "bell.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: preset.darkHex)))
                        }.buttonStyle(.plain)
                    }
                    .padding(.top, geo.safeAreaInsets.top + 8)
                    .padding(.horizontal, Theme.pad)

                    Spacer()

                    BudgetMascot(preset: preset, isHealthy: spentRatio < 0.75)
                        .frame(height: 155)
                        .scaleEffect(appeared ? 1 : 0.75).opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.05), value: appeared)

                    Spacer()

                    VStack(spacing: 6) {
                        Text("RESTE DISPONIBLE")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: preset.darkHex).opacity(0.45)).kerning(2.0)
                        Text(remaining.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                            .font(.system(size: 68, weight: .black, design: .rounded))
                            .foregroundStyle(remaining > 0 ? Color(hex: preset.darkHex) : Color(hex: "E0654A"))
                            .contentTransition(.numericText())
                    }
                    .padding(.bottom, 32)
                    .offset(y: appeared ? 0 : 24).opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: appeared)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.54)
    }

    private var decorCircles: some View {
        ZStack {
            Circle().fill(Color(hex: preset.primaryHex).opacity(0.12)).frame(width: 260, height: 260)
                .offset(x: -UIScreen.main.bounds.width * 0.35, y: -60)
            Circle().fill(Color(hex: preset.primaryHex).opacity(0.07)).frame(width: 150, height: 150)
                .offset(x: UIScreen.main.bounds.width * 0.38, y: 70)
        }
    }

    // MARK: — Bottom sheet

    private var bottomSheet: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Theme.card(cs)).ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.07), radius: 20, x: 0, y: -4)

            VStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Theme.fg2(cs).opacity(0.18)).frame(width: 36, height: 5).padding(.top, 12)
                budgetProgressCard
                incomeExpenseRow
                recentTransactions
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.pad)
        }
        .frame(maxHeight: .infinity)
        .offset(y: appeared ? 0 : 60).opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: — Budget progress

    private var budgetProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Budget total")
                    .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Theme.fg2(cs))
                Spacer()
                Text(totalBudget.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                    .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.fg(cs))
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface(cs)).frame(height: 10)
                    Capsule()
                        .fill(LinearGradient(
                            colors: spentRatio > 0.85
                                ? [Color(hex: "E0654A"), Color(hex: "F5A623")]
                                : [Color(hex: preset.primaryHex), Color(hex: preset.primaryHex).opacity(0.7)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * CGFloat(spentRatio), height: 10)
                        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: spentRatio)
                }
            }.frame(height: 10)

            HStack {
                Text("Dépensé : \(totalSpent.formatted(.currency(code: "EUR").precision(.fractionLength(0))))")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
                Spacer()
                Text("\(Int(spentRatio * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(spentRatio > 0.85 ? Color(hex: "E0654A") : Color(hex: preset.primaryHex))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Theme.rM, style: .continuous).fill(Theme.surface(cs)))
    }

    // MARK: — Revenus / Dépenses

    private var incomeExpenseRow: some View {
        HStack(spacing: 12) {
            financeTile(label: "Revenus",  amount: totalIncome, icon: "arrow.down.circle.fill", color: Color(hex: "3DAA7D"))
            financeTile(label: "Dépenses", amount: totalSpent,  icon: "arrow.up.circle.fill",   color: Color(hex: "E0654A"))
        }
    }

    private func financeTile(label: String, amount: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(amount.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                    .font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(Theme.fg(cs))
                Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.rM, style: .continuous).fill(Theme.surface(cs)))
    }

    // MARK: — Transactions récentes

    private var recentTransactions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RÉCENT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.fg2(cs)).kerning(1.4)
                Spacer()
                Button("Tout voir") {}
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: preset.primaryHex)).buttonStyle(.plain)
            }
            ForEach(recentTx.prefix(3)) { tx in txRow(tx) }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Theme.rM, style: .continuous).fill(Theme.surface(cs)))
        .padding(.bottom, 100)
    }

    private func txRow(_ tx: MockTx) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: tx.colorHex).opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: tx.icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: tx.colorHex))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(tx.label).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Theme.fg(cs))
                Text(tx.project).font(.system(size: 11, weight: .regular, design: .rounded)).foregroundStyle(Theme.fg2(cs))
            }
            Spacer()
            Text((tx.isExpense ? "-" : "+") + tx.amount.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tx.isExpense ? Color(hex: "E0654A") : Color(hex: "3DAA7D"))
        }
    }
}

// MARK: - Budget Mascot

private struct BudgetMascot: View {
    let preset: ThemePreset
    let isHealthy: Bool
    @State private var breatheScale: CGFloat = 1
    @State private var floatOffset: CGFloat  = 0

    var body: some View {
        ZStack {
            Ellipse().fill(Color(hex: preset.primaryHex).opacity(0.15))
                .frame(width: 100, height: 18).blur(radius: 10).offset(y: 65 + floatOffset * 0.3)

            ZStack {
                Circle().fill(Color(hex: preset.primaryHex)).frame(width: 118, height: 118)
                    .shadow(color: Color(hex: preset.primaryHex).opacity(0.28), radius: 20, x: 0, y: 10)

                VStack(spacing: 0) {
                    if isHealthy {
                        HStack(spacing: 22) { HappyEye(); HappyEye() }.frame(height: 13).offset(y: -4)
                        SmilePath().stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: 36, height: 14).offset(y: 8)
                    } else {
                        HStack(spacing: 22) {
                            Circle().fill(Color.white).frame(width: 10, height: 10)
                            Circle().fill(Color.white).frame(width: 10, height: 10)
                        }.offset(y: -4)
                        WorriedMouth().stroke(Color.white, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: 26, height: 10).offset(y: 12)
                    }
                }
                ZStack {
                    Circle().fill(Color.white.opacity(0.25)).frame(width: 24, height: 24)
                    Text("€").font(.system(size: 11, weight: .black, design: .rounded)).foregroundStyle(Color.white)
                }.offset(x: 44, y: -34)
            }
            .scaleEffect(breatheScale).offset(y: floatOffset)

            Circle().fill(Color.white.opacity(0.4)).frame(width: 16, height: 16).offset(x: -72, y: -20)
            Circle().fill(Color(hex: preset.primaryHex).opacity(0.25)).frame(width: 11, height: 11).offset(x: 74, y: -40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { breatheScale = 1.05 }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.4)) { floatOffset = -9 }
        }
    }
}

private struct HappyEye: View {
    var body: some View {
        Arc(startDeg: 180, endDeg: 360)
            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 16, height: 8)
    }
}
private struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY), radius: rect.width * 0.48,
                 startAngle: .degrees(15), endAngle: .degrees(165), clockwise: false)
        return p
    }
}
private struct WorriedMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: rect.width * 0.48,
                 startAngle: .degrees(195), endAngle: .degrees(345), clockwise: false)
        return p
    }
}
private struct Arc: Shape {
    let startDeg: Double; let endDeg: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                 startAngle: .degrees(startDeg), endAngle: .degrees(endDeg), clockwise: false)
        return p
    }
}

// MARK: - Mock Data

struct MockTx: Identifiable {
    let id = UUID()
    let label: String; let project: String; let amount: Double
    let isExpense: Bool; let icon: String; let colorHex: String

    static let samples: [MockTx] = [
        MockTx(label: "Figma Pro",            project: "Design System", amount: 45,   isExpense: true,  icon: "paintbrush.fill", colorHex: "7C6FC4"),
        MockTx(label: "Acompte client",       project: "App iOS v2",   amount: 2500, isExpense: false, icon: "briefcase.fill",  colorHex: "3DAA7D"),
        MockTx(label: "Serveur DigitalOcean", project: "Infra",        amount: 28,   isExpense: true,  icon: "server.rack",     colorHex: "3A8FC4"),
    ]
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(context: PreviewSupport.context)
    }
}
