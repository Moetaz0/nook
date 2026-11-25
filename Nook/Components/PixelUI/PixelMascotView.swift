import SwiftUI

enum MascotMood { case idle, hop, sleeping, sad }

/// "Nooky", la tasse mascotte, dessinée pixel par pixel dans un Canvas (aucun asset requis)
struct PixelMascotView: View {
    var mood: MascotMood = .idle
    var size: CGFloat = 120

    private static func sprite(_ mood: MascotMood) -> [String] {
        func inner(_ m: [Int: Character]) -> String {
            var a = [Character](repeating: "w", count: 12)
            for (i, c) in m { a[i] = c }
            return String(a)
        }
        func row(_ m: [Int: Character], _ handle: String) -> String { ".o" + inner(m) + "o" + handle }
        var eyes: [Int: Character] = [:], r4: [Int: Character] = [:], r5: [Int: Character] = [:]
        switch mood {
        case .idle:     eyes = [2: "e", 9: "e"]; r4 = [1: "r", 10: "r", 4: "m", 7: "m"]; r5 = [5: "m", 6: "m"]
        case .hop:      eyes = [2: "e", 9: "e"]; r4 = [1: "r", 10: "r", 2: "e", 9: "e"]; r5 = [4: "m", 5: "m", 6: "m", 7: "m"]
        case .sleeping: eyes = [1: "e", 2: "e", 9: "e", 10: "e"]; r4 = [1: "r", 10: "r"]; r5 = [5: "m", 6: "m"]
        case .sad:      eyes = [2: "e", 9: "e"]; r4 = [2: "c", 9: "c", 5: "m", 6: "m"]; r5 = [4: "m", 7: "m"]
        }
        return [
            "." + String(repeating: "o", count: 14) + "..",
            ".o" + String(repeating: "b", count: 12) + "o..",
            row([:], "oo"),
            row(eyes, ".o"),
            row(r4, ".o"),
            row(r5, "oo"),
            row([:], ".."),
            row([:], ".."),
            ".." + String(repeating: "o", count: 12) + "...",
            "." + String(repeating: "o", count: 15) + ".",
        ]
    }

    private static func color(_ c: Character) -> Color? {
        switch c {
        case "o", "e", "m": return Color(hex: 0x3B2416)
        case "w": return Color(hex: 0xFFF4D6)
        case "b": return Color(hex: 0x7B4A2D)
        case "r": return PixelTheme.rose
        case "c": return Color(hex: 0x6EC6FF)
        default: return nil
        }
    }

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { g, s in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let rows = Self.sprite(mood)
                let w = rows.map(\.count).max() ?? 1
                let px = max(1, floor(min(s.width / CGFloat(w), s.height / CGFloat(rows.count + 4))))
                var up: CGFloat = 0
                switch mood {
                case .idle: up = CGFloat((sin(t * 3) * 0.5 + 0.5).rounded()) * px
                case .hop: up = (CGFloat(abs(sin(t * 5))) * 3).rounded() * px
                case .sleeping: up = sin(t * 1.5) > 0 ? px : 0
                case .sad: up = 0
                }
                let x0 = ((s.width - CGFloat(w) * px) / 2).rounded()
                let y0 = s.height - CGFloat(rows.count) * px - px * 2 - up
                for (y, row) in rows.enumerated() {
                    for (x, ch) in row.enumerated() {
                        if let c = Self.color(ch) {
                            g.fill(Path(CGRect(x: x0 + CGFloat(x) * px, y: y0 + CGFloat(y) * px, width: px, height: px)), with: .color(c))
                        }
                    }
                }
                if mood == .idle || mood == .hop {   // vapeur
                    for i in 0..<2 {
                        let ph = (t * 0.8 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                        let sy = ((y0 - px - CGFloat(ph) * px * 4) / px).rounded() * px
                        let sx = x0 + px * CGFloat(5 + i * 5) + (ph > 0.5 ? px : 0)
                        g.fill(Path(CGRect(x: sx, y: sy, width: px, height: px)), with: .color(PixelTheme.ink.opacity(1 - ph)))
                    }
                }
                if mood == .sleeping {               // Zzz
                    let p = (t * 0.6).truncatingRemainder(dividingBy: 1)
                    g.draw(Text("z").font(.system(size: px * 3, weight: .black, design: .monospaced))
                        .foregroundStyle(PixelTheme.ink.opacity(1 - p)),
                           at: CGPoint(x: x0 + CGFloat(w) * px * 0.8 + p * px * 3, y: y0 - p * px * 5))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
