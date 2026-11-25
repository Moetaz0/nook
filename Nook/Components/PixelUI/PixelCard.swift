import SwiftUI

struct PixelCard<Content: View>: View {
    var fill: Color = PixelTheme.surface
    @ViewBuilder var content: Content
    var body: some View {
        content
            .foregroundStyle(PixelTheme.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelFrame(fill: fill)
            .padding(.trailing, 4).padding(.bottom, 4)
    }
}
