import SwiftUI

struct ThemePalettePicker: View {
    let selectedHex: String
    let canAccessPremiumThemes: Bool
    let onSelect: (String) -> Void
    let onLockedTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var displayedSelectedHex: String {
        Theme.effectiveThemeHex(
            for: selectedHex,
            canAccessPremiumThemes: canAccessPremiumThemes
        )
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                ForEach(Theme.presets) { preset in
                    let isPremiumPreset = Theme.isPremiumPreset(preset.primaryHex)
                    let isLocked = isPremiumPreset && !canAccessPremiumThemes
                    let isSelected = displayedSelectedHex == preset.primaryHex

                    Button {
                        if isLocked {
                            onLockedTap()
                        } else {
                            onSelect(preset.primaryHex)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(preset.color)
                                .frame(width: 36, height: 36)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: isSelected ? 2 : 0)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: Theme.freePresets.last?.primaryHex ?? "FF8A5B"))
                                    )
                            }
                        }
                        .scaleEffect(isSelected ? 1.04 : 1)
                        .opacity(isLocked && !isSelected ? 0.88 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.text(preset.nameKey))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 2)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.76), value: displayedSelectedHex)
        .animation(.spring(response: 0.25, dampingFraction: 0.76), value: canAccessPremiumThemes)
        .animation(.spring(response: 0.25, dampingFraction: 0.76), value: colorScheme)
    }
}
