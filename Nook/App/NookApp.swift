import SwiftUI
import SwiftData
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct NookApp: App {
    @AppStorage("theme") private var theme = "system"     // system | light | dark
    @AppStorage("lang") private var lang = "fr"           // fr | en | ar
    @State private var env: AppEnvironment

    init() {
        AppConfig.configureFirebase()                      // doit précéder la création des services
        _env = State(initialValue: AppEnvironment())
    }

    private var scheme: ColorScheme? { theme == "light" ? .light : (theme == "dark" ? .dark : nil) }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .environment(\.locale, Locale(identifier: lang))
                .environment(\.layoutDirection, lang == "ar" ? .rightToLeft : .leftToRight)
                .preferredColorScheme(scheme)
                .animation(.easeInOut(duration: 0.5), value: theme)
                .modifier(ThemeTransition(theme: theme))
                .modelContainer(for: FavoriteSpot.self)
                #if canImport(GoogleSignIn)
                .onOpenURL { _ = GIDSignIn.sharedInstance.handle($0) }
                #endif
        }
    }
}
