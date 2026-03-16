import SwiftUI

struct SplashView: View {
    let hasActiveHabit: Bool
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    @Environment(\.colorScheme) private var cs
    @State private var appeared = false

    private let preset = Theme.presets[0]

    var body: some View {
        ZStack {
            Theme.canvas(cs).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Zone illustration (fond couleur, mascotte)
                ZStack {
                    Color(hex: preset.softHex).ignoresSafeArea(edges: .top)

                    // Arcs Headspace en fond
                    SplashArcs(preset: preset)

                    // Mascotte centrée
                    VStack(spacing: 0) {
                        SplashMascot(preset: preset)
                            .offset(y: appeared ? 0 : 30)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.15), value: appeared)

                        VStack(spacing: 6) {
                            Text("Focus")
                                .font(.system(size: 52, weight: .heavy, design: .rounded))
                                .foregroundStyle(Theme.fg(.light))
                            + Text("One")
                                .font(.system(size: 52, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(hex: preset.primaryHex))

                            Text(L10n.text("splash.subtitle"))
                                .font(Theme.body(17, .medium))
                                .foregroundStyle(Theme.fg2(.light))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3), value: appeared)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.55)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0, bottomLeadingRadius: Theme.rXL + 6,
                        bottomTrailingRadius: Theme.rXL + 6, topTrailingRadius: 0,
                        style: .continuous
                    )
                )

                // ── Zone CTA crème
                VStack(alignment: .leading, spacing: 14) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 10) {
                        bulletRow(icon: "checkmark.circle.fill", text: L10n.text("splash.bullet.one"))
                        bulletRow(icon: "flame.fill",            text: L10n.text("splash.bullet.two"))
                    }

                    Spacer()

                    VStack(spacing: 10) {
                        PrimaryButton(
                            title: L10n.text("common.cta.get_started"),
                            tintHex: preset.primaryHex,
                            action: onPrimaryAction
                        )

                        if hasActiveHabit {
                            Button(L10n.text("common.cta.continue"), action: onSecondaryAction)
                                .font(Theme.body(15, .semibold))
                                .foregroundStyle(Theme.fg2(cs))
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, Theme.pad)
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: preset.primaryHex))
                .frame(width: 24)
            Text(text)
                .font(Theme.body(16))
                .foregroundStyle(Theme.fg(cs))
        }
    }
}

// MARK: - Mascotte splash

private struct SplashMascot: View {
    let preset: ThemePreset
    @State private var float = false

    var body: some View {
        ZStack {
            // Ombre portée
            Ellipse()
                .fill(Color(hex: preset.primaryHex).opacity(0.2))
                .frame(width: 110, height: 20)
                .blur(radius: 8)
                .offset(y: 85)
                .scaleEffect(x: float ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: float)

            // Corps
            ZStack {
                Circle()
                    .fill(Color(hex: preset.primaryHex))
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: preset.primaryHex).opacity(0.4), radius: 24, x: 0, y: 12)

                // Visage neutre / accueillant
                Group {
                    // Yeux
                    HStack(spacing: 22) {
                        Circle().fill(Color.white).frame(width: 12, height: 12)
                        Circle().fill(Color.white).frame(width: 12, height: 12)
                    }
                    .offset(y: -6)

                    // Sourire léger
                    Path { p in
                        p.addArc(center: .zero, radius: 20,
                                 startAngle: .degrees(15), endAngle: .degrees(165),
                                 clockwise: false)
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 20)
                    .offset(y: 18)
                }
            }
            .offset(y: float ? -8 : 8)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: float)
        }
        .frame(height: 180)
        .onAppear { float = true }
    }
}

// MARK: - Arcs décoratifs fond splash

private struct SplashArcs: View {
    let preset: ThemePreset

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.12))
                .frame(width: 280, height: 280)
                .offset(x: -100, y: 80)

            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.18))
                .frame(width: 180, height: 180)
                .offset(x: 110, y: -60)

            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 50, height: 50)
                .offset(x: -120, y: -70)

            Circle()
                .fill(Color(hex: preset.primaryHex).opacity(0.35))
                .frame(width: 28, height: 28)
                .offset(x: 120, y: 80)
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashView(hasActiveHabit: false, onPrimaryAction: {}, onSecondaryAction: {})
                .preferredColorScheme(.light)
            SplashView(hasActiveHabit: false, onPrimaryAction: {}, onSecondaryAction: {})
                .preferredColorScheme(.dark)
        }
    }
}
