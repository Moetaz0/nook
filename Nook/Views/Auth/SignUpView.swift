import SwiftUI

struct SignUpView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var email = ""
    @State private var pseudo = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var avatar = 0
    @State private var submitted = false

    private var valid: Bool {
        Validators.email(email) == nil && Validators.pseudo(pseudo) == nil && Validators.password(password) == nil
            && Validators.confirm(password, confirm) == nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("auth.signup").pixelFont(20)
                Text("auth.avatar").pixelFont(9).frame(maxWidth: .infinity, alignment: .leading)
                PixelAvatarPicker(selection: $avatar, isPlus: env.purchases.isPlus)
                PixelTextField(title: "auth.pseudo", text: $pseudo, error: Validators.live(pseudo, submitted: submitted, Validators.pseudo))
                PixelTextField(title: "auth.email", text: $email, error: Validators.live(email, submitted: submitted, Validators.email), keyboard: .emailAddress)
                PixelTextField(title: "auth.password", text: $password, secure: true, error: Validators.live(password, submitted: submitted, Validators.password))
                PixelGauge(icon: "lock.fill", label: "auth.strength", value: Validators.strength(password),
                           color: PixelTheme.quality(Validators.strength(password)))
                PixelTextField(title: "auth.confirm", text: $confirm, secure: true,
                               error: Validators.live(confirm, submitted: submitted) { Validators.confirm(password, $0) })
                if let e = env.auth.error { Text(LocalizedStringKey(e)).pixelFont(9).foregroundStyle(.red) }
                PixelButton("auth.signup", isLoading: env.auth.isBusy) {
                    submitted = true
                    guard valid else { return }
                    Task { await env.auth.signUp(email: email, password: password, pseudo: pseudo, avatarId: avatar) }
                }
            }
            .foregroundStyle(PixelTheme.ink).padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PixelBackground())
        .onAppear { env.auth.error = nil }
    }
}
