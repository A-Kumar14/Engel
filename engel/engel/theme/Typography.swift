import SwiftUI

enum AppTypography {
    static let displayXL = Font.custom("Fraunces", size: ThemeTokens.typography.displayXL)
    static let displayLG = Font.custom("Fraunces", size: ThemeTokens.typography.displayLG)
    static let displayMD = Font.custom("Fraunces", size: ThemeTokens.typography.displayMD)
    static let displaySM = Font.custom("Fraunces", size: ThemeTokens.typography.displaySM)
    static let body = Font.custom("JetBrains Mono", size: ThemeTokens.typography.body)
    static let monoSM = Font.custom("JetBrains Mono", size: ThemeTokens.typography.monoSM)
    static let monoXS = Font.custom("JetBrains Mono", size: ThemeTokens.typography.monoXS)
    static let caption = Font.custom("JetBrains Mono", size: ThemeTokens.typography.caption)

    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("Fraunces", size: size).weight(weight)
    }

    static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("JetBrains Mono", size: size).weight(weight)
    }
}
