import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var email = ""
    @State private var submitted = false
    @State private var sent = false

    var body: some View {
        VStack(spacing: 20) {
            PixelMascotView(mood: sent ? .hop : .idle, size: 140)
            Text("auth.reset.title").pixelFont(16).multilineTextAlignment(.center)
            if sent {
                Text("auth.reset.sent").pixelFont(10).multilineTextAlignment(.center).foregroundStyle(PixelTheme.green)
                    .transition(.scale.combined(with: .opacity))
            } else {
                PixelTextField(title: "auth.email", text: $email, error: Validators.live(email, submitted: submitted, Validators.email), keyboard: .emailAddress)
                if let e = env.auth.error { Text(LocalizedStringKey(e)).pixelFont(9).foregroundStyle(.red) }
                PixelButton("auth.send", isLoading: env.auth.isBusy) {
                    submitted = true
                    guard Validators.email(email) == nil else { return }
                    Task { if await env.auth.reset(email: email) { withAnimation(.bouncy) { sent = true } } }
                }
            }
            Spacer()
        }
        .foregroundStyle(PixelTheme.ink).padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PixelBackground())
        .onAppear { env.auth.error = nil }
    }
}
