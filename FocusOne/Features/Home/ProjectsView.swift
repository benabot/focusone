import SwiftUI
import CoreData

// MARK: - ProjectsView

struct ProjectsView: View {
    @Environment(\.colorScheme) private var cs
    @State private var appeared = false
    @State private var showAddProject = false
    private let context: NSManagedObjectContext

    private var preset: ThemePreset { Theme.preset(for: Theme.defaultThemeHex) }
    private let projects: [MockProject] = MockProject.samples

    init(context: NSManagedObjectContext) { self.context = context }

    var body: some View {
        ZStack {
            Color(hex: preset.softHex).ignoresSafeArea()
            VStack(spacing: 0) {
                hero
                projectsList
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.1)) { appeared = true }
        }
    }

    // MARK: — Hero

    private var hero: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                Color(hex: preset.softHex)
                Circle().fill(Color(hex: preset.primaryHex).opacity(0.13))
                    .frame(width: 180, height: 180)
                    .offset(x: UIScreen.main.bounds.width - 70, y: 10)
                Circle().fill(Color.white.opacity(0.3)).frame(width: 70, height: 70)
                    .offset(x: UIScreen.main.bounds.width - 30, y: -40)

                VStack(alignment: .leading, spacing: 6) {
                    Text("PROJETS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: preset.primaryHex)).kerning(1.8)
                    Text("Mes projets")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: preset.darkHex))
                    Text("\(projects.count) projets actifs")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: preset.darkHex).opacity(0.5))
                }
                .padding(.horizontal, Theme.pad)
                .padding(.top, geo.safeAreaInsets.top + 16)
                .padding(.bottom, 28)
            }
        }
        .frame(height: 185)
    }

    // MARK: — Liste projets

    private var projectsList: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Theme.card(cs)).ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: -3)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(Theme.fg2(cs).opacity(0.18)).frame(width: 36, height: 5).padding(.top, 12)

                    ForEach(projects) { project in projectCard(project) }

                    // Bouton ajouter
                    Button {
                        showAddProject = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(Color(hex: preset.primaryHex).opacity(0.12)).frame(width: 44, height: 44)
                                Image(systemName: "plus").font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color(hex: preset.primaryHex))
                            }
                            Text("Nouveau projet")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(hex: preset.primaryHex))
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: Theme.rM, style: .continuous)
                            .stroke(Color(hex: preset.primaryHex).opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .background(RoundedRectangle(cornerRadius: Theme.rM, style: .continuous)
                                .fill(Color(hex: preset.primaryHex).opacity(0.04))))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, Theme.pad)
            }
        }
        .frame(maxHeight: .infinity)
        .offset(y: appeared ? 0 : 50).opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: appeared)
    }

    // MARK: — Project card

    private func projectCard(_ p: MockProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: p.colorHex).opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: p.icon).font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: p.colorHex))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(Theme.fg(cs))
                    Text(p.client).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(Theme.fg2(cs))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(p.remaining.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(p.remaining > 0 ? Color(hex: "3DAA7D") : Color(hex: "E0654A"))
                    Text("restant").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
                }
            }

            // Barre de progression
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surface(cs)).frame(height: 7)
                    Capsule().fill(Color(hex: p.colorHex)).frame(width: g.size.width * CGFloat(p.ratio), height: 7)
                }
            }.frame(height: 7)

            HStack {
                Text("\(Int(p.ratio * 100))% utilisé")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
                Spacer()
                Text("Budget : \(p.budget.formatted(.currency(code: "EUR").precision(.fractionLength(0))))")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(Theme.fg2(cs))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
            .fill(Theme.surface(cs))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4))
    }
}

// MARK: - Mock Project

struct MockProject: Identifiable {
    let id = UUID()
    let name: String; let client: String; let budget: Double
    let spent: Double; let icon: String; let colorHex: String
    var remaining: Double { budget - spent }
    var ratio: Double { min(spent / budget, 1.0) }

    static let samples: [MockProject] = [
        MockProject(name: "App iOS v2",     client: "Acme Corp",    budget: 8000, spent: 3200, icon: "iphone",           colorHex: "3A8FC4"),
        MockProject(name: "Design System",  client: "Startup XYZ",  budget: 3500, spent: 2900, icon: "paintbrush.fill",  colorHex: "7C6FC4"),
        MockProject(name: "Infra & DevOps", client: "Perso",        budget: 900,  spent: 420,  icon: "server.rack",      colorHex: "3DAA7D"),
        MockProject(name: "Site vitrine",   client: "Boulangerie",  budget: 1500, spent: 800,  icon: "globe",            colorHex: "F47D31"),
    ]
}

struct ProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectsView(context: PreviewSupport.context)
    }
}
