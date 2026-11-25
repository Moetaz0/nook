import Foundation
import UIKit
#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseCore
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct AuthSession: Equatable { let uid: String; let email: String }

@MainActor protocol AuthService: AnyObject {
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(email: String, password: String) async throws -> AuthSession
    func signInWithGoogle() async throws -> AuthSession
    func sendReset(email: String) async throws
    func signOut() throws
    /// Appelle le handler immédiatement puis à chaque changement. Retourne une fonction d'annulation.
    func observe(_ handler: @escaping (AuthSession?) -> Void) -> () -> Void
}

// MARK: - Mock (aucun compte requis). Compte démo : demo@nook.app / Nook1234
@MainActor final class MockAuthService: AuthService {
    private var accounts: [String: (pw: String, uid: String)] = ["demo@nook.app": ("Nook1234", "demo")]
    private var handlers: [UUID: (AuthSession?) -> Void] = [:]
    private var current: AuthSession?

    private func publish(_ s: AuthSession?) -> AuthSession? {
        current = s; handlers.values.forEach { $0(s) }; return s
    }
    func signIn(email: String, password: String) async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(600))
        guard let a = accounts[email.lowercased()], a.pw == password else { throw AppError.auth("err.auth.invalid") }
        return publish(AuthSession(uid: a.uid, email: email))!
    }
    func signUp(email: String, password: String) async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(600))
        guard accounts[email.lowercased()] == nil else { throw AppError.auth("err.auth.exists") }
        let uid = UUID().uuidString
        accounts[email.lowercased()] = (password, uid)
        return publish(AuthSession(uid: uid, email: email))!
    }
    func signInWithGoogle() async throws -> AuthSession {
        try await Task.sleep(for: .milliseconds(600))
        return publish(AuthSession(uid: "demo", email: "demo@nook.app"))!
    }
    func sendReset(email: String) async throws {
        try await Task.sleep(for: .milliseconds(500))
        guard accounts[email.lowercased()] != nil else { throw AppError.auth("err.auth.invalid") }
    }
    func signOut() throws { _ = publish(nil) }
    func observe(_ handler: @escaping (AuthSession?) -> Void) -> () -> Void {
        let id = UUID(); handlers[id] = handler; handler(current)
        return { [weak self] in self?.handlers[id] = nil }
    }
}

// MARK: - Firebase Auth (actif si le package Firebase est ajouté ET un vrai GoogleService-Info.plist est présent)
#if canImport(FirebaseAuth)
@MainActor final class FirebaseAuthService: AuthService {
    private static func session(_ u: User) -> AuthSession { AuthSession(uid: u.uid, email: u.email ?? "") }

    static func map(_ e: Error) -> AppError {
        let ns = e as NSError
        guard ns.domain == "FIRAuthErrorDomain" else {
            return ns.domain == NSURLErrorDomain ? .network : .auth("err.auth.generic")
        }
        switch ns.code {
        case 17004, 17008, 17009, 17011: return .auth("err.auth.invalid")   // credentials / email / wrong password / no user
        case 17007: return .auth("err.auth.exists")                          // email already in use
        case 17026: return .auth("err.password.weak")
        case 17020: return .network
        default: return .auth("err.auth.generic")
        }
    }
    func signIn(email: String, password: String) async throws -> AuthSession {
        do { return Self.session(try await Auth.auth().signIn(withEmail: email, password: password).user) }
        catch { throw Self.map(error) }
    }
    func signUp(email: String, password: String) async throws -> AuthSession {
        do { return Self.session(try await Auth.auth().createUser(withEmail: email, password: password).user) }
        catch { throw Self.map(error) }
    }
    func signInWithGoogle() async throws -> AuthSession {
        #if canImport(GoogleSignIn)
        guard let clientID = FirebaseApp.app()?.options.clientID, let vc = UIApplication.shared.nookRootVC else {
            throw AppError.auth("err.auth.generic")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: vc)
            guard let idToken = result.user.idToken?.tokenString else { throw AppError.auth("err.auth.generic") }
            let cred = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            return Self.session(try await Auth.auth().signIn(with: cred).user)
        } catch let e as AppError { throw e } catch { throw Self.map(error) }
        #else
        throw AppError.auth("err.auth.generic")
        #endif
    }
    func sendReset(email: String) async throws {
        do { try await Auth.auth().sendPasswordReset(withEmail: email) } catch { throw Self.map(error) }
    }
    func signOut() throws {
        try Auth.auth().signOut()
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }
    func observe(_ handler: @escaping (AuthSession?) -> Void) -> () -> Void {
        let h = Auth.auth().addStateDidChangeListener { _, user in handler(user.map(Self.session)) }
        return { Auth.auth().removeStateDidChangeListener(h) }
    }
}
#endif
