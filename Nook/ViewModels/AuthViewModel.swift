import Foundation
import Observation

@MainActor @Observable final class AuthViewModel {
    enum Phase { case loading, signedOut, signedIn }
    var phase: Phase = .loading
    var user: NookUser?
    var isBusy = false
    var error: String?

    @ObservationIgnored private let service: AuthService
    @ObservationIgnored private let data: DataService
    @ObservationIgnored private var isSigningUp = false
    @ObservationIgnored private var stop: (() -> Void)?

    init(service: AuthService, data: DataService) {
        self.service = service; self.data = data
        stop = service.observe { [weak self] s in Task { @MainActor in await self?.handle(s) } }
    }

    private func handle(_ s: AuthSession?) async {
        guard !isSigningUp else { return }
        guard let s else { user = nil; phase = .signedOut; return }
        if let u = try? await data.user(uid: s.uid) {
            user = u
        } else {   // première connexion Google : profil créé automatiquement
            let base = s.email.split(separator: "@").first.map(String.init) ?? "nooker"
            let u = NookUser(id: s.uid, email: s.email, pseudo: String(base.prefix(12)) + String(Int.random(in: 10...99)), avatarId: 0)
            try? await data.createUser(u)
            user = u
        }
        phase = .signedIn
    }

    func signIn(email: String, password: String) async {
        isBusy = true; error = nil; defer { isBusy = false }
        do { await handle(try await service.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)) }
        catch { self.error = AppError.key(for: error) }
    }

    func signUp(email: String, password: String, pseudo: String, avatarId: Int) async {
        isBusy = true; error = nil; isSigningUp = true
        defer { isBusy = false; isSigningUp = false }
        guard await data.isPseudoAvailable(pseudo) else { error = "err.pseudo.taken"; return }
        do {
            let s = try await service.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password)
            let u = NookUser(id: s.uid, email: s.email, pseudo: pseudo, avatarId: avatarId)
            try await data.createUser(u)
            user = u; phase = .signedIn
        } catch { self.error = AppError.key(for: error) }
    }

    func google() async {
        isBusy = true; error = nil; defer { isBusy = false }
        do { await handle(try await service.signInWithGoogle()) } catch { self.error = AppError.key(for: error) }
    }

    func reset(email: String) async -> Bool {
        isBusy = true; error = nil; defer { isBusy = false }
        do { try await service.sendReset(email: email.trimmingCharacters(in: .whitespaces)); return true }
        catch { self.error = AppError.key(for: error); return false }
    }

    func signOut() { try? service.signOut(); user = nil; phase = .signedOut }
    func update(_ u: NookUser) { user = u }
}
