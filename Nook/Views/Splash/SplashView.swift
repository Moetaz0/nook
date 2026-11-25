import SwiftUI

struct SplashView: View {
    var onDone: () -> Void
    @State private var show = false
    var body: some View {
        VStack(spacing: 22) {
            PixelMascotView(mood: .hop, size: 170)
            Text(verbatim: "NOOK").pixelFont(38).foregroundStyle(PixelTheme.accent)
                .shadow(color: PixelTheme.ink, radius: 0, x: 4, y: 4)
                .scaleEffect(show ? 1 : 0.2).opacity(show ? 1 : 0)
            Text("app.tagline").pixelFont(10).foregroundStyle(PixelTheme.ink.opacity(0.8))
                .multilineTextAlignment(.center).opacity(show ? 1 : 0)
        }
        .task {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.45)) { show = true }
            try? await Task.sleep(for: .seconds(2))
            onDone()
        }
    }
}

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    private let pages: [(MascotMood, String, String)] = [
        (.hop, "onb.1.title", "onb.1.body"), (.idle, "onb.2.title", "onb.2.body"), (.sleeping, "onb.3.title", "onb.3.body")
    ]
    var body: some View {
        VStack(spacing: 16) {
            HStack { Spacer(); Button { onDone() } label: { Text("onb.skip").pixelFont(10) }.foregroundStyle(PixelTheme.ink) }
                .padding(.horizontal)
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 24) {
                        PixelMascotView(mood: pages[i].0, size: 190)
                        Text(LocalizedStringKey(pages[i].1)).pixelFont(16).multilineTextAlignment(.center)
                        Text(LocalizedStringKey(pages[i].2)).pixelFont(10).multilineTextAlignment(.center).lineSpacing(6)
                            .foregroundStyle(PixelTheme.ink.opacity(0.8))
                    }
                    .foregroundStyle(PixelTheme.ink).padding(.horizontal, 28).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            PixelButton(page == pages.count - 1 ? "onb.start" : "onb.next") {
                if page == pages.count - 1 { onDone() } else { withAnimation(.snappy) { page += 1 } }
            }.padding(.horizontal, 28).padding(.bottom, 20)
        }
    }
}
