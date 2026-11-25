import SwiftUI

/// Avatar pixel 8x8 symétrique généré depuis l'identifiant
struct PixelAvatarView: View {
    let id: Int
    var size: CGFloat = 56

    var body: some View {
        Canvas { g, s in
            var seed = UInt64(id &* 7919 &+ 13)
            func next() -> Bool {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return (seed >> 33) % 100 < 55
            }
            let palette: [Color] = [PixelTheme.green, PixelTheme.orange, PixelTheme.rose, PixelTheme.lamp,
                                    Color(hex: 0x5BC0EB), Color(hex: 0x9B5DE5), Color(hex: 0xE63946), Color(hex: 0x2A9D8F)]
            let c = palette[abs(id) % palette.count]
            let cell = s.width / 8
            for y in 0..<8 {
                for x in 0..<4 where next() {
                    for xx in [x, 7 - x] {
                        g.fill(Path(CGRect(x: CGFloat(xx) * cell, y: CGFloat(y) * cell, width: cell, height: cell)), with: .color(c))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .padding(4)
        .pixelFrame(fill: PixelTheme.surface, shadow: false)
    }
}

/// Sélecteur : avatars 0-7 gratuits, 8-11 exclusifs Nook+
struct PixelAvatarPicker: View {
    @Binding var selection: Int
    var isPlus: Bool
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(0..<12, id: \.self) { i in
                let locked = i >= 8 && !isPlus
                Button { if !locked { withAnimation(.bouncy) { selection = i } } } label: {
                    PixelAvatarView(id: i, size: 52)
                        .overlay { if locked { Image(systemName: "lock.fill").foregroundStyle(PixelTheme.ink) } }
                        .opacity(locked ? 0.45 : 1)
                        .scaleEffect(selection == i ? 1.12 : 1)
                        .overlay(alignment: .topTrailing) {
                            if selection == i { Image(systemName: "checkmark.square.fill").foregroundStyle(PixelTheme.green) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
