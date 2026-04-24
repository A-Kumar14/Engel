import SwiftUI

enum ThemeTokens {
    static let colors = Colors()
    static let spacing = Spacing()
    static let radii = Radii()
    static let typography = Typography()
}

struct Colors {
    let bg = Color(hex: 0x0A0A0B)
    let bgElevated = Color("engel-cream")
    let ink = Color("engel-ink")
    let inkDim = Color("engel-ink-dim")
    let inkFaint = Color(hex: 0x3A3731)
    let green = Color("engel-green")
    let greenDeep = Color(hex: 0x14532D)
    let red = Color("engel-red")
    let redDeep = Color(hex: 0x4C1414)
    let line = Color.white.opacity(0.08)
    let lineSoft = Color.white.opacity(0.05)
    let bgCard = Color(hex: 0x141413)
}

struct Spacing {
    let x1: CGFloat = 4
    let x2: CGFloat = 8
    let x3: CGFloat = 12
    let x4: CGFloat = 16
    let x5: CGFloat = 20
    let x6: CGFloat = 24
    let x8: CGFloat = 32
    let x10: CGFloat = 40
    let x12: CGFloat = 48
    let x16: CGFloat = 64
    let x20: CGFloat = 80
    let x30: CGFloat = 120
}

struct Radii {
    let small: CGFloat = 12
    let medium: CGFloat = 16
    let large: CGFloat = 20
}

struct Typography {
    let displayXL: CGFloat = 34
    let displayLG: CGFloat = 28
    let displayMD: CGFloat = 22
    let displaySM: CGFloat = 18
    let body: CGFloat = 15
    let monoSM: CGFloat = 13
    let monoXS: CGFloat = 11
    let caption: CGFloat = 10
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
