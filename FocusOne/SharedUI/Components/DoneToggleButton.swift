import SwiftUI

struct DoneToggleButton: View {
    let isDone: Bool
    let tintHex: String
    let action: () -> Void

    @State private var pressed = false
    @State private var sparkle = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                sparkle = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sparkle = false
            }
            action()
        } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isDone
                            ? Color(hex: tintHex)
                            : Color(hex: tintHex).opacity(0.12)
                    )

                // Sparkle overlay quand on passe à done
                if sparkle && isDone {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .transition(.opacity)
                }

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isDone ? 0.22 : 0))
                            .frame(width: 32, height: 32)

                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(isDone ? .white : Color(hex: tintHex))
                            .scaleEffect(sparkle ? 1.2 : 1)
                            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: sparkle)
                    }

                    Text(isDone ? L10n.text("home.done.button.on") : L10n.text("home.done.button.off"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isDone ? .white : Color(hex: tintHex))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .shadow(
                color: isDone ? Color(hex: tintHex).opacity(0.35) : .clear,
                radius: 12, x: 0, y: 6
            )
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
