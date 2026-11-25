import SwiftUI
import CoreLocation
#if canImport(FirebaseCore)
import FirebaseCore
#endif

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: alpha)
    }
    /// Couleur adaptative clair / sombre
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
    }
}

extension UIApplication {
    var nookRootVC: UIViewController? {
        var vc = connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }
}

enum LoadState<T> { case idle, loading, loaded(T), empty, failed(String) }

enum AppError: LocalizedError {
    case network, server(Int), decoding, auth(String), unknown
    var key: String {
        switch self {
        case .network: return "err.network"
        case .server: return "err.server"
        case .decoding: return "err.decoding"
        case .auth(let k): return k
        case .unknown: return "err.unknown"
        }
    }
    var errorDescription: String? { L10n.t(key) }
    static func key(for error: Error) -> String {
        if let e = error as? AppError { return e.key }
        if error is URLError { return "err.network" }
        return "err.unknown"
    }
}

enum L10n {
    /// Traduction hors SwiftUI (suit la langue choisie dans les réglages)
    static func t(_ key: String) -> String {
        let lang = UserDefaults.standard.string(forKey: "lang") ?? "fr"
        if let p = Bundle.main.path(forResource: lang, ofType: "lproj"), let b = Bundle(path: p) {
            return b.localizedString(forKey: key, value: key, table: nil)
        }
        return key
    }
}

enum AppConfig {
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815) // Tunis
    /// true seulement si un vrai GoogleService-Info.plist est présent
    static var firebaseReady: Bool {
        guard let p = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let d = NSDictionary(contentsOfFile: p), let key = d["API_KEY"] as? String else { return false }
        return !key.contains("PLACEHOLDER")
    }
    static var demoMode: Bool { !firebaseReady }
    static func configureFirebase() {
        #if canImport(FirebaseCore)
        if firebaseReady { FirebaseApp.configure() }
        #endif
    }
}

enum Validators {
    /// N'affiche l'erreur qu'après saisie ou tentative d'envoi
    static func live(_ text: String, submitted: Bool, _ rule: (String) -> String?) -> String? {
        (submitted || !text.isEmpty) ? rule(text) : nil
    }
    static func email(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return "err.email.required" }
        return t.range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) == nil
            ? "err.email.invalid" : nil
    }
    static func passwordRequired(_ s: String) -> String? { s.isEmpty ? "err.password.required" : nil }
    static func password(_ s: String) -> String? {
        if s.isEmpty { return "err.password.required" }
        if s.count < 8 { return "err.password.short" }
        if !s.contains(where: \.isLetter) || !s.contains(where: \.isNumber) { return "err.password.weak" }
        return nil
    }
    static func strength(_ s: String) -> Double {
        var v = 0.0
        if s.count >= 8 { v += 0.34 }
        if s.contains(where: \.isLetter) && s.contains(where: \.isNumber) { v += 0.33 }
        if s.count >= 12 || s.contains(where: { !$0.isLetter && !$0.isNumber }) { v += 0.33 }
        return v
    }
    static func confirm(_ a: String, _ b: String) -> String? { a != b ? "err.confirm.mismatch" : nil }
    static func pseudo(_ s: String) -> String? {
        if s.isEmpty { return "err.pseudo.required" }
        return s.range(of: "^[A-Za-z0-9_]{3,16}$", options: .regularExpression) == nil ? "err.pseudo.invalid" : nil
    }
    static func rating(_ r: Int) -> String? { r == 0 ? "err.rating.required" : nil }
    static func comment(_ s: String) -> String? { s.count > 200 ? "err.comment.long" : nil }
    static func price(_ s: String) -> String? {
        if s.isEmpty { return nil }
        guard let v = Double(s.replacingOccurrences(of: ",", with: ".")), v >= 0, v <= 50 else { return "err.price.invalid" }
        return nil
    }
}
