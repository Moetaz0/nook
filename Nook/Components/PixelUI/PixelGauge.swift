import SwiftUI

/// Jauge à 10 segments qui se remplit en cascade
struct PixelGauge: View {
    let icon: String
    let label: LocalizedStringKey
    let value: Double          // 0...1
    var color: Color = PixelTheme.green
    @State private var shown = 0.0

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).frame(width: 22)
            Text(label).pixelFont(9).frame(width: 84, alignment: .leading).lineLimit(1).minimumScaleFactor(0.6)
            HStack(spacing: 2) {
                ForEach(0..<10, id: \.self) { i in
                    Rectangle()
                        .fill(Double(i) < shown * 10 ? color : PixelTheme.ink.opacity(0.15))
                        .frame(height: 14)
                        .animation(.easeOut(duration: 0.15).delay(Double(i) * 0.04), value: shown)
                }
            }
        }
        .foregroundStyle(PixelTheme.ink)
        .onAppear { shown = value }
        .onChange(of: value) { _, v in shown = v }
    }
}
