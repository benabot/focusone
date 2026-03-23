import SwiftUI

struct ThemePreset: Identifiable, Hashable {
    let id: String
    let nameKey: String
    let primaryHex: String
    let softHex: String

    var color: Color { Color(hex: primaryHex) }
    var softColor: Color { Color(hex: softHex) }
}

enum Theme {
    static let presets: [ThemePreset] = [
        ThemePreset(id: "sunrise", nameKey: "theme.sunrise", primaryHex: "FF8A5B", softHex: "FFD6C7"),
        ThemePreset(id: "mango", nameKey: "theme.mango", primaryHex: "FFB347", softHex: "FFE5BC"),
        ThemePreset(id: "mint", nameKey: "theme.mint", primaryHex: "34C9A5", softHex: "C4F0E5"),
        ThemePreset(id: "lagoon", nameKey: "theme.lagoon", primaryHex: "4AA8FF", softHex: "CCE5FF"),
        ThemePreset(id: "berry", nameKey: "theme.berry", primaryHex: "E56DB1", softHex: "F8D1E8"),
        ThemePreset(id: "violet", nameKey: "theme.violet", primaryHex: "9B8CFF", softHex: "E2DCFF"),
        ThemePreset(id: "coral", nameKey: "theme.coral", primaryHex: "FF6E6E", softHex: "FFD1D1"),
        ThemePreset(id: "forest", nameKey: "theme.forest", primaryHex: "48A16C", softHex: "CFE7D7")
    ]

    static let freeThemeCount = PremiumConfig.freeThemeCount
    static let defaultThemeHex = freePresets.first?.primaryHex ?? presets[0].primaryHex
    static let accent = Color(hex: "FF8A5B")
    static let backgroundTint = Color(hex: "FFF5EC")

    static var freePresets: [ThemePreset] {
        Array(presets.prefix(freeThemeCount))
    }

    static var premiumPresets: [ThemePreset] {
        Array(presets.dropFirst(freeThemeCount))
    }

    static func accessiblePresets(canAccessPremiumThemes: Bool) -> [ThemePreset] {
        canAccessPremiumThemes ? presets : freePresets
    }

    static func isPremiumPreset(_ hex: String) -> Bool {
        premiumPresets.contains(where: { $0.primaryHex == hex })
    }

    static func effectiveThemeHex(for hex: String, canAccessPremiumThemes: Bool) -> String {
        guard canAccessPremiumThemes || !isPremiumPreset(hex) else {
            return defaultThemeHex
        }
        return hex
    }

    static func effectivePreset(for hex: String, canAccessPremiumThemes: Bool) -> ThemePreset {
        preset(for: effectiveThemeHex(for: hex, canAccessPremiumThemes: canAccessPremiumThemes))
    }

    // Core design tokens used across the redesigned surfaces.
    static let cornerRadiusLarge: CGFloat = 24
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 22

    static let radiusSmall: CGFloat = 16
    static let radiusMedium: CGFloat = 20
    static let radiusLarge: CGFloat = cornerRadiusLarge

    static let spacingXS: CGFloat = 8
    static let spacingS: CGFloat = 12
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = spacing
    static let spacingXL: CGFloat = 32

    static func preset(for hex: String) -> ThemePreset {
        presets.first(where: { $0.primaryHex == hex }) ?? presets[0]
    }

    static func backgroundGradient(for preset: ThemePreset, scheme: ColorScheme) -> LinearGradient {
        let top = scheme == .dark ? Color(hex: "151821") : preset.softColor.opacity(0.62)
        let bottom = scheme == .dark ? Color(hex: "0F1117") : backgroundTint
        return LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "1C2230") : Color.white.opacity(0.88)
    }

    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F7F8FA") : Color(hex: "1C1D21")
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "C7CAD3") : Color(hex: "5D6373")
    }
}

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = Theme.spacingXS
    static let s: CGFloat = Theme.spacingS
    static let m: CGFloat = Theme.spacingM
    static let l: CGFloat = Theme.spacingL
    static let xl: CGFloat = Theme.spacingXL
    static let xxl: CGFloat = 40
}

enum AppRadius {
    static let small: CGFloat = Theme.radiusSmall
    static let medium: CGFloat = Theme.radiusMedium
    static let large: CGFloat = 28
    static let capsule: CGFloat = 999
}

enum AppTypography {
    static let overline = Font.system(size: 11, weight: .bold, design: .rounded)
    static let section = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .medium, design: .rounded)
    static let bodySmall = Font.system(size: 15, weight: .medium, design: .rounded)
    static let title = Font.system(size: 34, weight: .bold, design: .rounded)
    static let heroValue = Font.system(size: 82, weight: .heavy, design: .rounded)
    static let cardValue = Font.system(size: 28, weight: .bold, design: .rounded)
    static let cta = Font.system(size: 18, weight: .bold, design: .rounded)
}

enum AppColors {
    static let accent = Theme.accent
    static let canvas = Theme.backgroundTint
    static let success = Color(hex: "48A16C")

    static func textPrimary(for scheme: ColorScheme) -> Color {
        Theme.textPrimary(for: scheme)
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        Theme.textSecondary(for: scheme)
    }

    static func surface(for scheme: ColorScheme) -> Color {
        Theme.surface(for: scheme)
    }

    static func elevatedSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.96)
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch clean.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
