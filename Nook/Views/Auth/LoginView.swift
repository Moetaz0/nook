import SwiftUI

struct LoginView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var email = ""
    @State private var password = ""
    @State private var submitted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PixelMascotView(mood: env.auth.error != nil ? .sad : .idle, size: 120)
                Text("auth.login").pixelFont(20).foregroundStyle(PixelTheme.ink)
                PixelTextField(title: "auth.email", text: $email,
                               error: Validators.live(email, submitted: submitted, Validators.email), keyboard: .emailAddress)
                PixelTextField(title: "auth.password", text: $password, secure: true,
                               error: Validators.live(password, submitted: submitted, Validators.passwordRequired))
                if let e = env.auth.error {
                    Text(LocalizedStringKey(e)).pixelFont(9).foregroundStyle(.red).multilineTextAlignment(.center)
                }
                PixelButton("auth.login", isLoading: env.auth.isBusy) {
                    submitted = true
                    guard Validators.email(email) == nil, Validators.passwordRequired(password) == nil else { return }
                    Task { await env.auth.signIn(email: email, password: password) }
                }
                Text("auth.or").pixelFont(9).foregroundStyle(PixelTheme.ink.opacity(0.6))
                PixelButton("auth.google", color: PixelTheme.rose) { Task { await env.auth.google() } }
                NavigationLink(value: AuthRoute.forgot) { Text("auth.forgot").pixelFont(9).underline() }
                NavigationLink(value: AuthRoute.signUp) { Text("auth.noaccount").pixelFont(10).underline() }
                if AppConfig.demoMode {
                    Text(verbatim: "Demo: demo@nook.app / Nook1234").pixelFont(8).foregroundStyle(PixelTheme.ink.opacity(0.5))
                }
            }
            .foregroundStyle(PixelTheme.ink).padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PixelBackground())
        .onAppear { env.auth.error = nil }
    }
}
