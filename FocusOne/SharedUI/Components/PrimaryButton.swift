import SwiftUI

struct PrimaryButton: View {
    let title: String
    let tintHex: String
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { pressed = false }
            }
            action()
        } label: {
            Text(title)
                .font(Theme.body(17, .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: Theme.rL, style: .continuous)
                        .fill(Color(hex: tintHex))
                        .shadow(color: Color(hex: tintHex).opacity(0.35), radius: 14, x: 0, y: 6)
                )
                .scaleEffect(pressed ? 0.97 : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
    }
}
