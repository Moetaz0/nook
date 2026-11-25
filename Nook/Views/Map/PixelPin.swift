import SwiftUI

struct PixelPin: View {
    let type: SpotType
    var selected: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: type.icon)
                .font(.system(size: selected ? 15 : 13, weight: .bold))
                .foregroundStyle(selected ? PixelTheme.midnight : PixelTheme.ink)
                .frame(width: selected ? 36 : 30, height: selected ? 36 : 30)
                .pixelFrame(fill: selected ? PixelTheme.accent : PixelTheme.surface, shadow: true)

            Rectangle()
                .fill(PixelTheme.ink)
                .frame(width: 4, height: 8)
        }
        .scaleEffect(selected ? 1.12 : 1.0)
        .animation(.snappy, value: selected)
    }
}
