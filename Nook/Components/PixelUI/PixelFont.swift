import SwiftUI
import UIKit

/// Police pixel (Press Start 2P / Silkscreen si ajoutées dans Resources/Fonts), sinon monospaced.
/// Arabe : Cairo si présente, sinon police système arrondie.
enum PixelFont {
    static func font(_ size: CGFloat, lang: String) -> Font {
        if lang == "ar" {
            if UIFont(name: "Cairo-Bold", size: size) != nil { return .custom("Cairo-Bold", size: size + 2) }
            return .system(size: size + 2, weight: .bold, design: .rounded)
        }
        for name in ["PressStart2P-Regular", "Silkscreen-Regular", "Silkscreen-Bold"] where UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: .heavy, design: .monospaced)
    }
}

struct PixelTextStyle: ViewModifier {
    @AppStorage("lang") private var lang = "fr"
    var size: CGFloat
    func body(content: Content) -> some View { content.font(PixelFont.font(size, lang: lang)) }
}

extension View {
    func pixelFont(_ size: CGFloat = 12) -> some View { modifier(PixelTextStyle(size: size)) }
    func pixelFrame(fill: Color = PixelTheme.surface, border: Color = PixelTheme.ink, shadow: Bool = true) -> some View {
        modifier(PixelFrame(fill: fill, border: border, shadow: shadow))
    }
}
