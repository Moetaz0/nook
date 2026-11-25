import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @AppStorage("onboarded") private var onboarded = false
    @State private var splashDone = false

    var body: some View {
        @Bindable var ads = env.ads
        ZStack {
            PixelBackground()
            if !splashDone {
                SplashView { withAnimation(.easeInOut) { splashDone = true } }.transition(.opacity)
            } else if !onboarded {
                OnboardingView { withAnimation { onboarded = true } }.transition(.move(edge: .trailing))
            } else {
                switch env.auth.phase {
                case .loading: LoadingView()
                case .signedOut: AuthFlow().transition(.opacity)
                case .signedIn: MainTabView().transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: env.auth.phase)
        .fullScreenCover(isPresented: $ads.showPlaceholder) { PlaceholderInterstitialView() }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ExplorerView().tabItem { Label("tab.explore", systemImage: "magnifyingglass") }
            SpotMapView().tabItem { Label("tab.map", systemImage: "map.fill") }
            FavoritesView().tabItem { Label("tab.favorites", systemImage: "heart.fill") }
            ProfileView().tabItem { Label("tab.profile", systemImage: "person.fill") }
            SettingsView().tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
        }
        .tint(PixelTheme.accent)
        .toolbarBackground(PixelTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

enum AuthRoute: Hashable { case signUp, forgot }

struct AuthFlow: View {
    var body: some View {
        NavigationStack {
            LoginView()
                .navigationDestination(for: AuthRoute.self) { r in
                    switch r { case .signUp: SignUpView(); case .forgot: ForgotPasswordView() }
                }
        }
        .tint(PixelTheme.accent)
    }
}
