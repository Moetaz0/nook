# Nook : trouve ta place pour étudier (SwiftUI, iOS 17+)

App pixel-art 8-bit : check-in de 10 secondes (bruit, affluence, Wi-Fi, prises, prix du café), XP, niveaux
(Stagiaire → Habitué → Maire du spot), badges, classement.

## Démarrage rapide (2 options)

**Option A : mode démo, zéro dépendance (recommandé pour tester)**
```bash
brew install xcodegen
xcodegen --spec project-lite.yml
open Nook.xcodeproj
```
Lance sur simulateur iPhone (iOS 17+). Compte démo : `demo@nook.app` / `Nook1234` (ou « Continuer avec Google » : mock).

**Option B : version complète (Firebase + Google Sign-In + AdMob)**
```bash
xcodegen            # utilise project.yml et télécharge les packages SPM
open Nook.xcodeproj
```
Packages SPM déclarés dans `project.yml` :
| Package | Produits | URL |
|---|---|---|
| firebase-ios-sdk | FirebaseAuth, FirebaseFirestore | https://github.com/firebase/firebase-ios-sdk |
| GoogleSignIn-iOS | GoogleSignIn | https://github.com/google/GoogleSignIn-iOS |
| Google Mobile Ads | GoogleMobileAds (v12.x) | https://github.com/googleads/swift-package-manager-google-mobile-ads |

**Sans XcodeGen :** Xcode → New Project → iOS App (SwiftUI, nom `Nook`, iOS 17) → supprime `ContentView.swift`
et `NookApp.swift` générés → glisse le dossier `Nook/` dans le projet → ajoute les packages ci-dessus via
*File ▸ Add Package Dependencies* → remplace l'Info.plist par `Nook/Resources/Info.plist` (ou copie ses clés).

## Brancher Firebase (réel)
1. Console Firebase → nouveau projet → ajoute une app iOS avec le bundle id `app.nook.Nook`.
2. Active **Authentication** (Email/Password + Google) et **Cloud Firestore**.
3. Télécharge `GoogleService-Info.plist` et **remplace** `Nook/Resources/GoogleService-Info.plist`.
4. Dans `Info.plist`, remplace `com.googleusercontent.apps.PLACEHOLDER` par ton `REVERSED_CLIENT_ID` (URL scheme Google Sign-In).
5. Colle `firestore.rules` dans l'onglet Rules de Firestore.

Le code détecte automatiquement le fichier : tant que `API_KEY` contient `PLACEHOLDER`, l'app utilise les services *mock*
(`MockAuthService`, `MockDataService`) et reste 100 % fonctionnelle.

## Publicités (IDs de TEST Google uniquement)
App `ca-app-pub-3940256099942544~1458002511` · Bannière `.../2934735716` (bas de l'écran Explorer) ·
Interstitielle `.../4411468910` (après un check-in, **1 fois toutes les 3 actions**, jamais pour Nook+).
Sans le package, des pubs factices s'affichent à la place.

## Nook+ (paiement sandbox)
`Nook.storekit` est déjà lié au scheme (Run). Produit `app.nook.plus`. Sans config StoreKit, le bouton active Nook+ en mode démo.

## Polices pixel (optionnel)
Ajoute `PressStart2P-Regular.ttf` (ou `Silkscreen`) et `Cairo-Bold.ttf` dans `Resources/Fonts`, coche la cible,
puis déclare-les dans `Info.plist` → `UIAppFonts`. Sinon : police monospaced de secours.

## Architecture (MVVM + services injectés)
```
Nook/
├── App/          NookApp, AppEnvironment (DI), RootView (+ MainTabView, AuthFlow)
├── Models/       Spot, CheckIn/Review, NookUser/Level/Badge, WeatherInfo, FavoriteSpot (SwiftData), SampleData
├── ViewModels/   Auth, Explorer, SpotDetail, CheckIn
├── Services/     AuthService (Firebase + Mock), DataService (Firestore + Mock), Network (Overpass, Open-Meteo),
│                 LocationService, XPService, AdService, PurchaseService
├── Components/PixelUI/  PixelTheme, PixelFont, PixelBorder, PixelCard, PixelButton, PixelTextField, PixelGauge,
│                        XPBarView, PixelConfettiView, PixelMascotView, PixelAvatar, PixelBadgeView
├── Views/        Splash(+Onboarding), Auth(Login/SignUp/Forgot), Explorer, Map, SpotDetail, CheckIn, Favorites,
│                 Profile, Settings(+Paywall), Shared (Loading/Error/Empty)
├── Utilities/    Support.swift (LoadState, AppError, Validators, L10n, AppConfig)
└── Resources/    Localizable.xcstrings (FR/EN/AR), Info.plist, GoogleService-Info.plist (placeholder), Nook.storekit, Assets
```

## Couverture du cahier des charges
SwiftUI ✔ · Firebase Auth + Firestore ✔ · Email/mdp + Google ✔ · 11 écrans (+ paywall, overlay XP) ✔ · navigation ✔ ·
validation avec messages clairs ✔ · API REST (Overpass + Open-Meteo) ✔ · animations ✔ · thème Système/Clair/Sombre ✔ ·
FR/EN/AR + RTL ✔ · chargement/erreur/vide ✔ · AdMob Banner + Interstitial (IDs test) ✔ ·
Bonus : StoreKit sandbox, MapKit/CoreLocation, SwiftData hors ligne, cache Firestore.
