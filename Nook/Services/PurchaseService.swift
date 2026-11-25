import StoreKit
import Observation

/// Nook+ (achat unique, sandbox via Nook.storekit) : retire les pubs + avatars exclusifs
@MainActor @Observable final class PurchaseService {
    static let productID = "app.nook.plus"
    var isPlus = UserDefaults.standard.bool(forKey: "isPlus")
    var product: Product?
    var isBusy = false

    func load() async {
        product = try? await Product.products(for: [Self.productID]).first
        await refresh()
        Task { for await _ in Transaction.updates { await refresh() } }
    }
    func refresh() async {
        for await r in Transaction.currentEntitlements {
            if case .verified(let t) = r, t.productID == Self.productID { setPlus(true) }
        }
    }
    func buy() async {
        guard let product else { setPlus(true); return }    // démo : pas de configuration StoreKit
        isBusy = true; defer { isBusy = false }
        if let result = try? await product.purchase(), case .success(let v) = result, case .verified(let t) = v {
            await t.finish(); setPlus(true)
        }
    }
    func resetDemo() { setPlus(false) }
    private func setPlus(_ v: Bool) { isPlus = v; UserDefaults.standard.set(v, forKey: "isPlus") }
}
