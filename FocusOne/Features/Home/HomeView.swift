import SwiftUI
import CoreData

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var cs
    @State private var showEdit = false
    @State private var appeared = false
    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        ctx = context
        _viewModel = StateObject(wrappedValue: HomeViewModel(context: context))
    }

    private var preset: ThemePreset {
        Theme.preset(for: viewModel.habit?.colorHex ?? Theme.defaultThemeHex)
    }

    var body: some View {
        ZStack {
            // Fond crème plein écran — signature Headspace
            Color(hex: preset.softHex).ignoresSafeArea()

            if let habit = viewModel.habit {
                habitContent(habit: habit)
            } else {
                emptyState
            }
        }
        .onAppear {
            viewModel.load()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: viewModel.load) {
            OnboardingView(
                context: ctx, mode: .edit,
                onFinished: { showEdit = false; viewModel.load() },
                onCancel:   { showEdit = false }
            )
            .presentationDetents([.large])
        }
    }

    // MARK: — Layout principal

    private func habitContent(habit: Habit) -> some View {
        VStack(spacing: 0) {
            // Zone supérieure : mascotte + streak (plein fond coloré)
            topArea(habit: habit)

            // Zone inférieure : cartes sur fond blanc/crème
            bottomSheet(habit: habit)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: — Top area (75% écran)

    private func topArea(habit: Habit) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Fond couleur thème
                Color(hex: preset.softHex)

                // Décor : grands cercles flottants
                decorCircles

                VStack(spacing: 0) {
                    // ── Barre du haut
                    topBar(habit: habit)
                        .padding(.top, geo.safeAreaInsets.top + 8)
                        .padding(.horizontal, Theme.pad)

                    Spacer()

                    // ── Mascotte centrée
                    HeadspaceMascot(preset: preset, doneToday: viewModel.doneToday)
                        .frame(height: 190)
                        .scaleEffect(appeared ? 1 : 0.75)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.05), value: appeared)

                    Spacer()

                    // ── Streak au centre
                    streakDisplay
                        .padding(.bottom, 36)
                        .offset(y: appeared ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: appeared)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.60)
    }

    // MARK: — Décors flottants

    private var decorCircles: some View {
        ZStack {
            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.12))
                .frame(width: 280, height: 280)
                .offset(x: -UIScreen.main.bounds.width * 0.35, y: -60)

            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.08))
                .frame(width: 160, height: 160)
                .offset(x: UIScreen.main.bounds.width * 0.38, y: 80)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 60, height: 60)
                .offset(x: UIScreen.main.bounds.width * 0.30, y: -80)
        }
    }

    // MARK: — Top bar

    private func topBar(habit: Habit) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: preset.primaryHex))
                    .kerning(1.8)
                Text(habit.name)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: preset.darkHex))
                    .lineLimit(1)
            }

            Spacer()

            Button { showEdit = true } label: {
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: preset.darkHex))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: — Streak display

    private var streakDisplay: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 88, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: preset.darkHex))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.68), value: viewModel.currentStreak)

                Text(L10n.streakUnit(viewModel.currentStreak).uppercased())
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: preset.primaryHex))
                    .kerning(1.0)
                    .padding(.bottom, 16)
            }

            Text(L10n.text("home.streak.label").uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(hex: preset.darkHex).opacity(0.45))
                .kerning(2.2)
        }
    }

    // MARK: — Bottom sheet (fond blanc arrondi)

    private func bottomSheet(habit: Habit) -> some View {
        ZStack(alignment: .top) {
            // Fond blanc avec coins arrondis en haut
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Theme.card(cs))
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.07), radius: 20, x: 0, y: -4)

            VStack(spacing: 14) {
                // Handle pill
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Theme.fg2(cs).opacity(0.18))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                // Today status pill
                todayPill

                // Stats mini
                statsRow

                // Reminder
                if !viewModel.nextReminderText.isEmpty {
                    reminderRow
                }

                Spacer(minLength: 0)

                // CTA
                DoneToggleButton(isDone: viewModel.doneToday, tintHex: preset.primaryHex) {
                    viewModel.toggleDoneToday()
                }
                .padding(.bottom, 34)
            }
            .padding(.horizontal, Theme.pad)
        }
        .frame(maxHeight: .infinity)
        .offset(y: appeared ? 0 : 60)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: — Today pill

    private var todayPill: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(viewModel.doneToday
                          ? Color(hex: preset.primaryHex).opacity(0.15)
                          : Theme.surface(cs))
                    .frame(width: 36, height: 36)
                Image(systemName: viewModel.doneToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(viewModel.doneToday
                                     ? Color(hex: preset.primaryHex)
                                     : Theme.fg2(cs))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.doneToday
                     ? L10n.text("home.today.state.done")
                     : L10n.text("home.today.state.not_done"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.fg(cs))
                Text(todayDateString)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.fg2(cs))
            }

            Spacer()

            if viewModel.doneToday {
                Text("✦")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: preset.primaryHex))
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.rM, style: .continuous)
                .fill(Theme.surface(cs))
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.doneToday)
    }

    // MARK: — Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statPill(
                icon: "trophy.fill",
                value: "\(viewModel.bestStreak)",
                label: L10n.text("home.best.short")
            )
            statPill(
                icon: "chart.bar.fill",
                value: L10n.completionPercent(viewModel.completionRate7),
                label: L10n.text("stats.last7")
            )
        }
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: preset.primaryHex).opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: preset.primaryHex))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.fg(cs))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.fg2(cs))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.rM, style: .continuous)
                .fill(Theme.surface(cs))
        )
    }

    // MARK: — Reminder row

    private var reminderRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: preset.primaryHex))
            Text(viewModel.nextReminderText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.fg2(cs))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.rM, style: .continuous)
                .fill(Color(hex: preset.primaryHex).opacity(0.06))
        )
    }

    // MARK: — Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(Color(hex: Theme.defaultThemeHex))
            }
            Text(L10n.text("home.no_habit"))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "7A6E62"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: — Helpers

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return L10n.text("home.greeting.morning")
        case 12..<18: return L10n.text("home.greeting.afternoon")
        default:      return L10n.text("home.greeting.evening")
        }
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return f.string(from: Date())
    }
}

// MARK: - Headspace Mascot

private struct HeadspaceMascot: View {
    let preset: ThemePreset
    let doneToday: Bool

    @State private var breatheScale: CGFloat = 1.0
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Ombre douce sous le corps
            Ellipse()
                .fill(Color(hex: preset.primaryHex).opacity(0.18))
                .frame(width: 120, height: 24)
                .blur(radius: 12)
                .offset(y: 82 + floatOffset * 0.3)

            // Corps principal — cercle signature Headspace
            ZStack {
                // Corps
                Circle()
                    .fill(Color(hex: preset.primaryHex))
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: preset.primaryHex).opacity(0.30),
                            radius: 24, x: 0, y: 12)

                // Visage
                VStack(spacing: 0) {
                    if doneToday {
                        // Yeux fermés heureux (demi-cercles)
                        HStack(spacing: 26) {
                            HappyEye()
                            HappyEye()
                        }
                        .frame(height: 16)
                        .offset(y: -6)

                        // Sourire
                        SmilePath()
                            .stroke(Color.white,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 46, height: 18)
                            .offset(y: 10)
                    } else {
                        // Yeux ouverts neutres
                        HStack(spacing: 26) {
                            Circle().fill(Color.white).frame(width: 13, height: 13)
                            Circle().fill(Color.white).frame(width: 13, height: 13)
                        }
                        .offset(y: -6)

                        // Bouche neutre
                        Capsule()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 32, height: 5)
                            .offset(y: 12)
                    }
                }
            }
            .scaleEffect(breatheScale)
            .offset(y: floatOffset)

            // Petits cercles orbitaux
            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 22, height: 22)
                .offset(x: -88, y: -28)

            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.30))
                .frame(width: 14, height: 14)
                .offset(x: 90, y: -50)

            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 10, height: 10)
                .offset(x: 80, y: 40)
        }
        .onAppear {
            // Animation respiration lente
            withAnimation(
                .easeInOut(duration: 3.5)
                    .repeatForever(autoreverses: true)
            ) {
                breatheScale = 1.06
            }
            // Lévitation douce
            withAnimation(
                .easeInOut(duration: 2.8)
                    .repeatForever(autoreverses: true)
                    .delay(0.4)
            ) {
                floatOffset = -10
            }
        }
    }
}

// MARK: - Shapes

private struct HappyEye: View {
    var body: some View {
        Arc(startDeg: 180, endDeg: 360)
            .stroke(Color.white,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            .frame(width: 20, height: 10)
    }
}

private struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY),
                 radius: rect.width * 0.48,
                 startAngle: .degrees(15),
                 endAngle: .degrees(165),
                 clockwise: false)
        return p
    }
}

private struct Arc: Shape {
    let startDeg: Double
    let endDeg: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: rect.width / 2,
                 startAngle: .degrees(startDeg),
                 endAngle: .degrees(endDeg),
                 clockwise: false)
        return p
    }
}

// MARK: - Previews

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView(context: PreviewSupport.context).preferredColorScheme(.light)
            HomeView(context: PreviewSupport.context).preferredColorScheme(.dark)
        }
    }
}
