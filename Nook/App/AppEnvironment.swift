import SwiftUI

/// Conteneur de services (injection de dépendances)
@MainActor @Observable final class AppEnvironment {
    let data: DataService
    let auth: AuthViewModel
    let explorer: ExplorerViewModel
    let location = LocationService()
    let ads = AdService()
    let purchases = PurchaseService()

    init() {
        var d: DataService = MockDataService()
        var a: AuthService = MockAuthService()
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        if AppConfig.firebaseReady { d = FirestoreDataService(); a = FirebaseAuthService() }
        #endif
        data = d
        auth = AuthViewModel(service: a, data: d)
        explorer = ExplorerViewModel(data: d)
        ads.start()
        Task { await purchases.load() }
    }
}
