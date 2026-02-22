import SwiftUI

struct PrimaryButton: View {
    let title: String
    let tintHex: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingM)
                .background(Color(hex: tintHex))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
