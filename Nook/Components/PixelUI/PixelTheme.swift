import SwiftUI

enum PixelTheme {
    static let midnight = Color(hex: 0x1B1F3B)
    static let cream = Color(hex: 0xF6E8C3)
    static let green = Color(hex: 0x6BBF59)
    static let orange = Color(hex: 0xE07A3F)
    static let rose = Color(hex: 0xF28CB1)
    static let lamp = Color(hex: 0xFFD166)

    // Adaptatives : "café le jour" / "bibliothèque la nuit"
    static let bg = Color(light: 0xF6E8C3, dark: 0x1B1F3B)
    static let surface = Color(light: 0xFFF8E3, dark: 0x2A2F55)
    static let ink = Color(light: 0x3B2416, dark: 0xF6E8C3)
    static let accent = Color(light: 0xE07A3F, dark: 0xFFD166)

    /// 0 = mauvais, 1 = très bon
    static func quality(_ good: Double) -> Color {
        good >= 0.66 ? green : (good >= 0.36 ? lamp : rose)
    }
}

/// Fond d'écran commun
struct PixelBackground: View {
    var body: some View { PixelTheme.bg.ignoresSafeArea() }
}

/// Fondu soleil / lune au changement de thème
struct ThemeTransition: ViewModifier {
    let theme: String
    @State private var flash = false
    func body(content: Content) -> some View {
        content
            .overlay {
                if flash {
                    Image(systemName: theme == "dark" ? "moon.stars.fill" : "sun.max.fill")
                        .font(.system(size: 96)).foregroundStyle(PixelTheme.lamp)
                        .shadow(color: PixelTheme.lamp, radius: 20)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: theme) { _, _ in
                withAnimation(.bouncy) { flash = true }
                Task { try? await Task.sleep(for: .milliseconds(800)); withAnimation(.easeOut) { flash = false } }
            }
    }
}
