import SwiftUI
import UIKit

enum ThemeTokens {
    static let colors = Colors()
    static let spacing = Spacing()
    static let radii = Radii()
    static let typography = Typography()
}

struct Colors {
    let bg = Color(light: 0xF5F0E8, dark: 0x0A0A0B)
    let bgElevated = Color("engel-cream")
    let ink = Color("engel-ink")
    let inkDim = Color("engel-ink-dim")
    let inkFaint = Color(light: 0x9E9889, dark: 0x3A3731)
    let green = Color("engel-green")
    let greenDeep = Color(light: 0x14532D, dark: 0x22C55E)
    let red = Color("engel-red")
    let redDeep = Color(light: 0x4C1414, dark: 0xEF4444)
    let line = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white.withAlphaComponent(0.08)
            : .black.withAlphaComponent(0.08)
    })
    let lineSoft = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white.withAlphaComponent(0.05)
            : .black.withAlphaComponent(0.05)
    })
    let bgCard = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.078, blue: 0.075, alpha: 1)
            : UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
    })
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

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}
