import SwiftUI

/// Barre d'XP segmentée avec segments lumineux
struct XPBarView: View {
    let progress: Double       // 0...1
    var segments = 20
    @State private var shown = 0.0
    @State private var glow = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                let on = Double(i) + 1 <= shown * Double(segments)
                Rectangle()
                    .fill(on ? PixelTheme.green : PixelTheme.ink.opacity(0.15))
                    .frame(height: 18)
                    .shadow(color: on ? PixelTheme.green.opacity(glow ? 0.9 : 0.2) : .clear, radius: glow ? 6 : 2)
                    .animation(.easeOut(duration: 0.12).delay(Double(i) * 0.03), value: shown)
            }
        }
        .padding(4)
        .pixelFrame(fill: PixelTheme.surface, shadow: false)
        .onAppear {
            shown = progress
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { glow = true }
        }
        .onChange(of: progress) { _, v in shown = v }
    }
}
