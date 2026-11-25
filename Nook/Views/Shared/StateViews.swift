import SwiftUI

/// Mascotte endormie pendant le chargement
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            PixelMascotView(mood: .sleeping, size: 130)
            Text("state.loading").pixelFont(10).foregroundStyle(PixelTheme.ink.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Mascotte triste + bouton Réessayer
struct ErrorView: View {
    let messageKey: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            PixelMascotView(mood: .sad, size: 130)
            Text(LocalizedStringKey(messageKey)).pixelFont(10).multilineTextAlignment(.center).foregroundStyle(PixelTheme.ink)
            PixelButton("state.retry", action: retry).frame(maxWidth: 220)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    var messageKey = "state.empty"
    var body: some View {
        VStack(spacing: 16) {
            PixelMascotView(mood: .idle, size: 130)
            Text(LocalizedStringKey(messageKey)).pixelFont(10).multilineTextAlignment(.center)
                .foregroundStyle(PixelTheme.ink).padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
