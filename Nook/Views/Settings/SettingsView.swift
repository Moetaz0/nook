import SwiftUI
import StoreKit

struct SettingsView: View {
    @AppStorage("theme") private var theme = "system"
    @AppStorage("lang") private var lang = "fr"
    @Environment(AppEnvironment.self) private var env
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PixelCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label { Text("settings.theme") } icon: { Image(systemName: "circle.lefthalf.filled") }.pixelFont(11)
                            PixelSegmented(options: [("system", "theme.system"), ("light", "theme.light"), ("dark", "theme.dark")], selection: $theme)
                        }
                    }
                    PixelCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label { Text("settings.language") } icon: { Image(systemName: "globe") }.pixelFont(11)
                            PixelSegmented(options: [("fr", "FR"), ("en", "EN"), ("ar", "AR")], selection: $lang)
                        }
                    }
                    PixelCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label { Text("settings.plus") } icon: { Image(systemName: "sparkles") }.pixelFont(11)
                            if env.purchases.isPlus { Text("paywall.active").pixelFont(9).foregroundStyle(PixelTheme.green) }
                            else { PixelButton("paywall.title", color: PixelTheme.rose) { showPaywall = true } }
                        }
                    }
                    PixelButton("settings.signout", color: PixelTheme.orange) { env.auth.signOut() }
                    Text(verbatim: "Nook 1.0 · \(AppConfig.demoMode ? "demo" : "firebase")").pixelFont(8).opacity(0.5)
                }
                .foregroundStyle(PixelTheme.ink).padding()
            }
            .background(PixelBackground())
            .navigationTitle("tab.settings").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

struct PaywallView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            PixelBackground()
            VStack(spacing: 18) {
                PixelMascotView(mood: env.purchases.isPlus ? .hop : .idle, size: 130)
                Text("paywall.title").pixelFont(20)
                PixelCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label { Text("paywall.b1") } icon: { Image(systemName: "nosign") }
                        Label { Text("paywall.b2") } icon: { Image(systemName: "person.crop.square.fill") }
                    }.pixelFont(10)
                }
                if env.purchases.isPlus {
                    Text("paywall.active").pixelFont(11).foregroundStyle(PixelTheme.green)
                } else {
                    PixelButton("paywall.buy", isLoading: env.purchases.isBusy) { Task { await env.purchases.buy() } }
                    Text(env.purchases.product?.displayPrice ?? "2.99 $ · sandbox").pixelFont(9).opacity(0.7)
                }
                Button { dismiss() } label: { Text("ad.close").pixelFont(9).underline() }
                Spacer()
            }
            .foregroundStyle(PixelTheme.ink).padding(24).padding(.top, 20)
        }
    }
}
