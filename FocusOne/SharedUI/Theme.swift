import SwiftUI

// MARK: - ThemePreset

struct ThemePreset: Identifiable, Hashable {
    let id: String
    let nameKey: String
    let primaryHex: String
    let softHex: String
    let darkHex: String   // version plus sombre pour contraste texte

    var color: Color     { Color(hex: primaryHex) }
    var softColor: Color { Color(hex: softHex) }
    var darkColor: Color { Color(hex: darkHex) }
}

// MARK: - Theme

enum Theme {
    static let presets: [ThemePreset] = [
        ThemePreset(id: "tangerine", nameKey: "theme.sunrise",  primaryHex: "F47D31", softHex: "FDEBD7", darkHex: "C45E1A"),
        ThemePreset(id: "mango",     nameKey: "theme.mango",    primaryHex: "F5A623", softHex: "FEF0CC", darkHex: "C07C0A"),
        ThemePreset(id: "sage",      nameKey: "theme.mint",     primaryHex: "3DAA7D", softHex: "C8EAD9", darkHex: "2A7A58"),
        ThemePreset(id: "sky",       nameKey: "theme.lagoon",   primaryHex: "3A8FC4", softHex: "C5E2F5", darkHex: "26638A"),
        ThemePreset(id: "rose",      nameKey: "theme.berry",    primaryHex: "D95B7E", softHex: "F8CEDA", darkHex: "A33459"),
        ThemePreset(id: "lavender",  nameKey: "theme.violet",   primaryHex: "7C6FC4", softHex: "DDD8F5", darkHex: "5347A0"),
        ThemePreset(id: "coral",     nameKey: "theme.coral",    primaryHex: "E0654A", softHex: "FAD0C5", darkHex: "B03E28"),
        ThemePreset(id: "forest",    nameKey: "theme.forest",   primaryHex: "3D8A5E", softHex: "C4E2D1", darkHex: "285E3F")
    ]

    static let defaultThemeHex = presets[0].primaryHex

    // ── Canvas (fond d'écran)
    static let canvasLight  = Color(hex: "F6F0E8")   // crème Headspace
    static let canvasDark   = Color(hex: "18140F")
    static let cardLight    = Color(hex: "FFFFFF")
    static let cardDark     = Color(hex: "2C2620")
    static let surfaceLight = Color(hex: "EDE6DB")
    static let surfaceDark  = Color(hex: "3A3028")

    // ── Typo
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // ── Spacing
    static let pad: CGFloat   = 20
    static let xs:  CGFloat   = 6
    static let s:   CGFloat   = 10
    static let m:   CGFloat   = 14
    static let l:   CGFloat   = 20
    static let xl:  CGFloat   = 32

    // ── Radii — très généreux, Headspace-style
    static let rS:  CGFloat   = 14
    static let rM:  CGFloat   = 20
    static let rL:  CGFloat   = 28
    static let rXL: CGFloat   = 38

    // ── Semantic
    static func canvas(_ s: ColorScheme)  -> Color { s == .dark ? canvasDark  : canvasLight  }
    static func card(_ s: ColorScheme)    -> Color { s == .dark ? cardDark    : cardLight    }
    static func surface(_ s: ColorScheme) -> Color { s == .dark ? surfaceDark : surfaceLight }

    static func fg(_ s: ColorScheme)  -> Color {
        s == .dark ? Color(hex: "F6F0E8") : Color(hex: "1A1410")
    }
    static func fg2(_ s: ColorScheme) -> Color {
        s == .dark ? Color(hex: "B8A898") : Color(hex: "7A6E62")
    }

    static func preset(for hex: String) -> ThemePreset {
        presets.first { $0.primaryHex == hex } ?? presets[0]
    }

    // Compatibilité anciens appels
    static func displayFont(size: CGFloat, weight: Font.Weight = .bold) -> Font { display(size, weight) }
    static func bodyFont(size: CGFloat, weight: Font.Weight = .regular) -> Font { body(size, weight) }
    static func textPrimary(for s: ColorScheme) -> Color   { fg(s) }
    static func textSecondary(for s: ColorScheme) -> Color { fg2(s) }
    static func backgroundGradient(for _: ThemePreset, scheme s: ColorScheme) -> LinearGradient {
        LinearGradient(colors: [canvas(s), canvas(s)], startPoint: .top, endPoint: .bottom)
    }
    static let padding:    CGFloat = pad
    static let spacing:    CGFloat = l
    static let spacingXS:  CGFloat = xs
    static let spacingS:   CGFloat = s
    static let spacingM:   CGFloat = m
    static let spacingL:   CGFloat = l
    static let spacingXL:  CGFloat = xl
    static let radiusSmall:  CGFloat = rS
    static let radiusMedium: CGFloat = rM
    static let radiusLarge:  CGFloat = rL
    static let radiusXL:     CGFloat = rXL
    static let cornerRadiusLarge: CGFloat = rL
    static let backgroundTint = canvasLight
    static let accent = Color(hex: "F47D31")
}

// MARK: - Color hex

extension Color {
    init(hex: String) {
        let c = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: c).scanHexInt64(&n)
        let a, r, g, b: UInt64
        switch c.count {
        case 3:  (a,r,g,b) = (255,(n>>8)*17,(n>>4&0xF)*17,(n&0xF)*17)
        case 6:  (a,r,g,b) = (255, n>>16, n>>8 & 0xFF, n & 0xFF)
        case 8:  (a,r,g,b) = (n>>24, n>>16 & 0xFF, n>>8 & 0xFF, n & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
