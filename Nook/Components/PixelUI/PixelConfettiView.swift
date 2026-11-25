import SwiftUI

/// Explosion de confettis carrés (Canvas + TimelineView)
struct PixelConfettiView: View {
    private struct Particle {
        let angle = Double.random(in: (-Double.pi * 0.95)...(-Double.pi * 0.05))
        let speed = Double.random(in: 180...420)
        let size = CGFloat([6, 8, 10].randomElement()!)
        let color = [PixelTheme.green, PixelTheme.orange, PixelTheme.rose, PixelTheme.lamp, Color(hex: 0x5BC0EB)].randomElement()!
    }
    @State private var start = Date()
    @State private var parts = (0..<70).map { _ in Particle() }

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { g, size in
                let t = ctx.date.timeIntervalSince(start)
                guard t < 2.6 else { return }
                let fade = max(0, 1 - t / 2.6)
                for p in parts {
                    let x = size.width / 2 + cos(p.angle) * p.speed * t
                    let y = size.height * 0.5 + sin(p.angle) * p.speed * t + 520 * t * t
                    let r = CGRect(x: (x / 4).rounded() * 4, y: (y / 4).rounded() * 4, width: p.size, height: p.size)
                    g.fill(Path(r), with: .color(p.color.opacity(fade)))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
