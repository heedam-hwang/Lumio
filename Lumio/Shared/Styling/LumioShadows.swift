import SwiftUI

struct LumioShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

enum LumioShadows {
    static let floatingAction = LumioShadowStyle(
        color: LumioColors.floatingButtonShadow,
        radius: 8,
        x: 0,
        y: 4
    )
    static let menu = LumioShadowStyle(
        color: LumioColors.menuShadow,
        radius: 10,
        x: 0,
        y: 4
    )
    static let card = LumioShadowStyle(
        color: LumioColors.cardShadow,
        radius: 18,
        x: 0,
        y: 12
    )
    static let cover = LumioShadowStyle(
        color: LumioColors.coverShadow,
        radius: 12,
        x: 0,
        y: 8
    )
}

extension View {
    func lumioShadow(_ style: LumioShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
