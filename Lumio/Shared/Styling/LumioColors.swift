import SwiftUI

enum LumioColors {
    static let canvasWarm = Color(red: 247 / 255, green: 246 / 255, blue: 242 / 255)
    static let canvasWarmAlt = Color(red: 246 / 255, green: 245 / 255, blue: 240 / 255)

    static let cardSurface = Color.white.opacity(0.92)
    static let elevatedCardSurface = Color.white.opacity(0.9)
    static let softCardSurface = Color.white.opacity(0.88)
    static let cardStroke = Color.white.opacity(0.75)
    static let softCardStroke = Color.white.opacity(0.7)

    static let systemSecondarySurface = Color(uiColor: .secondarySystemBackground)

    static let accentFill = Color.accentColor
    static let accentSoftFill = Color.accentColor.opacity(0.1)
    static let accentSelectionFill = Color.accentColor.opacity(0.12)
    static let accentSelectionStroke = Color.accentColor.opacity(0.24)
    static let accentTokenFill = Color.accentColor.opacity(0.15)
    static let accentWordSelection = Color.accentColor.opacity(0.2)

    static let destructiveFill = Color.red
    static let destructiveSoftFill = Color.red.opacity(0.08)
    static let savedWordFill = Color.yellow.opacity(0.55)

    static let scrim = Color.black.opacity(0.25)
    static let tapScrim = Color.black.opacity(0.001)
    static let floatingButtonShadow = Color.black.opacity(0.2)
    static let menuShadow = Color.black.opacity(0.14)
    static let cardShadow = Color.black.opacity(0.06)
    static let coverShadow = Color.black.opacity(0.08)

    static let coverGradientStart = Color(red: 244 / 255, green: 235 / 255, blue: 208 / 255)
    static let coverGradientEnd = Color(red: 227 / 255, green: 214 / 255, blue: 175 / 255)
    static let coverSpineBlue = Color(red: 64 / 255, green: 102 / 255, blue: 191 / 255)
    static let coverSpineGold = Color(red: 243 / 255, green: 176 / 255, blue: 64 / 255)
    static let coverText = Color(red: 48 / 255, green: 45 / 255, blue: 39 / 255)
}
