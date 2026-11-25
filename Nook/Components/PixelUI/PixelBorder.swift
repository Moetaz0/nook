import SwiftUI

/// Rectangle aux coins "en escalier" (look 8-bit)
struct PixelRect: Shape {
    var notch: CGFloat = 4
    func path(in r: CGRect) -> Path {
        let n = notch
        var p = Path()
        p.move(to: CGPoint(x: r.minX + n, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.minY + n))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + n))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - n))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + n))
        p.addLine(to: CGPoint(x: r.minX + n, y: r.minY + n))
        p.closeSubpath()
        return p
    }
}

/// Cadre pixel : bordure épaisse + ombre dure décalée
struct PixelFrame: ViewModifier {
    var fill: Color
    var border: Color
    var shadow = true
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                if shadow { PixelRect().fill(PixelTheme.ink.opacity(0.35)).offset(x: 4, y: 4) }
                PixelRect().fill(border)
                PixelRect().fill(fill).padding(4)
            }
        )
    }
}
