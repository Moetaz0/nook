import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

/// IDs de TEST fournis par Google : ne jamais utiliser d'ID réels pendant le développement.
enum AdIDs {
    static let appID = "ca-app-pub-3940256099942544~1458002511"
    static let banner = "ca-app-pub-3940256099942544/2934735716"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
}

@MainActor @Observable final class AdService {
    static let interstitialEvery = 3      // 1 interstitielle toutes les 3 actions
    var actions = 0
    var showPlaceholder = false           // interstitielle factice si le SDK n'est pas installé
    #if canImport(GoogleMobileAds)
    @ObservationIgnored private var interstitial: InterstitialAd?
    #endif

    func start() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        Task { await loadInterstitial() }
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func loadInterstitial() async {
        interstitial = try? await InterstitialAd.load(with: AdIDs.interstitial, request: Request())
    }
    #endif

    /// À appeler après une action utilisateur (check-in). Affiche une interstitielle 1 fois sur 3, jamais pour Nook+.
    func completeAction(isPlus: Bool) {
        actions += 1
        guard !isPlus, actions % Self.interstitialEvery == 0 else { return }
        #if canImport(GoogleMobileAds)
        if let ad = interstitial {
            ad.present(from: nil)
            interstitial = nil
            Task { await loadInterstitial() }
        }
        #else
        showPlaceholder = true
        #endif
    }
}

struct AdBannerView: View {
    var body: some View {
        #if canImport(GoogleMobileAds)
        BannerRepresentable().frame(width: 320, height: 50)
        #else
        Text("AD · BANNER (TEST)").pixelFont(9).foregroundStyle(PixelTheme.ink.opacity(0.6))
            .frame(width: 320, height: 50).pixelFrame(fill: PixelTheme.bg, shadow: false)
        #endif
    }
}

#if canImport(GoogleMobileAds)
private struct BannerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let v = BannerView(adSize: AdSizeBanner)
        v.adUnitID = AdIDs.banner
        v.rootViewController = UIApplication.shared.nookRootVC
        v.load(Request())
        return v
    }
    func updateUIView(_ uiView: BannerView, context: Context) {}
}
#endif

/// Interstitielle factice (affichée uniquement quand Google Mobile Ads n'est pas installé)
struct PlaceholderInterstitialView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            PixelBackground()
            VStack(spacing: 20) {
                Text("ad.title").pixelFont(14)
                PixelMascotView(mood: .hop, size: 140)
                PixelButton("ad.close") { dismiss() }.padding(.horizontal, 40)
            }
        }
    }
}
