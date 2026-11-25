import SwiftUI

struct PixelBadgeView: View {
    let badge: Badge
    var unlocked = true
    var size: CGFloat = 56
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                PixelRect().fill(unlocked ? badge.color : PixelTheme.ink.opacity(0.15))
                Image(systemName: unlocked ? badge.icon : "lock.fill").font(.system(size: size * 0.4))
                    .foregroundStyle(unlocked ? PixelTheme.midnight : PixelTheme.ink.opacity(0.4))
            }
            .frame(width: size, height: size)
            Text(LocalizedStringKey(badge.titleKey)).pixelFont(7).multilineTextAlignment(.center)
                .foregroundStyle(PixelTheme.ink.opacity(unlocked ? 1 : 0.5))
        }
    }
}
