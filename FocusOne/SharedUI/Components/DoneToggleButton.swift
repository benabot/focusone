import SwiftUI

/// Bouton CTA principal — style Headspace "Start" button
/// Pill pleine largeur, avec animation de press et burst de complétion
struct DoneToggleButton: View {
    let isDone: Bool
    let tintHex: String
    let action: () -> Void

    @State private var pressed = false
    @State private var burst   = false
    @State private var checkScale: CGFloat = 1

    private var tint: Color { Color(hex: tintHex) }

    var body: some View {
        Button {
            triggerBurst()
            action()
        } label: {
            ZStack {
                // Fond — plein quand done, outline quand non
                Capsule()
                    .fill(isDone ? tint : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(isDone ? Color.clear : tint, lineWidth: 2)
                    )

                // Halo de burst (flash blanc)
                if burst {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .transition(.opacity)
                }

                // Contenu
                HStack(spacing: 16) {
                    // Cercle icône
                    ZStack {
                        Circle()
                            .fill(isDone
                                  ? Color.white.opacity(0.22)
                                  : tint.opacity(0.10))
                            .frame(width: 46, height: 46)

                        Image(systemName: isDone ? "checkmark" : "circle")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(isDone ? Color.white : tint)
                            .scaleEffect(checkScale)
                    }

                    Text(isDone
                         ? L10n.text("home.done.button.on")
                         : L10n.text("home.done.button.off"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isDone ? .white : tint)
                }
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            // Ombre colorée quand actif
            .shadow(
                color: isDone ? tint.opacity(0.38) : .clear,
                radius: 18, x: 0, y: 8
            )
            // Press + burst scale
            .scaleEffect(pressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }

    private func triggerBurst() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) {
            burst = true
            checkScale = 1.4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                burst = false
                checkScale = 1
            }
        }
    }
}
