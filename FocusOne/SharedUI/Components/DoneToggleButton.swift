import SwiftUI

struct DoneToggleButton: View {
    let isDone: Bool
    let tintHex: String
    let action: () -> Void

    @State private var animatePulse = false

    var body: some View {
        Button {
            action()
            animatePulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                animatePulse = false
            }
        } label: {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                Text(isDone ? L10n.text("home.done.button.on") : L10n.text("home.done.button.off"))
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingM)
            .background(Color(hex: tintHex))
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
            .scaleEffect(animatePulse ? 1.04 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.65), value: animatePulse)
        }
        .buttonStyle(.plain)
    }
}
