import Foundation

/// Données de démonstration (mode sans Firebase / secours si Overpass est injoignable)
enum SampleData {
    private static func s(_ i: Int, _ n: String, _ t: SpotType, _ dLat: Double, _ dLng: Double, _ h: String,
                          _ no: Double, _ cr: Double, _ wi: Double, _ ou: Double, _ price: Double?) -> Spot {
        Spot(id: "sample-\(i)", name: n, type: t,
             latitude: AppConfig.defaultCoordinate.latitude + dLat, longitude: AppConfig.defaultCoordinate.longitude + dLng,
             opening: h,
             live: LiveStats(noise: no, crowd: cr, wifi: wi, outlets: ou, coffeePrice: price,
                             updatedAt: Date().addingTimeInterval(-Double(i) * 900), count: 3 + i))
    }
    static let spots: [Spot] = [
        s(1, "Café Mokka", .cafe, 0.004, 0.003, "Mo-Su 07:00-23:00", 0.35, 0.40, 0.80, 0.70, 2.5),
        s(2, "Bibliothèque Centrale", .library, -0.006, 0.004, "Mo-Sa 08:30-18:00", 0.10, 0.55, 0.50, 0.60, nil),
        s(3, "Coworking La Ruche", .coworking, 0.009, -0.006, "Mo-Fr 08:00-20:00", 0.30, 0.30, 0.95, 0.95, 3.0),
        s(4, "Café du Lac", .cafe, 0.012, 0.011, "Mo-Su 06:30-00:00", 0.80, 0.85, 0.60, 0.30, 3.2),
        s(5, "Salon Lecture Bleu", .cafe, -0.003, -0.008, "Mo-Su 09:00-22:00", 0.20, 0.25, 0.70, 0.80, 2.8),
        s(6, "Médiathèque du Quartier", .library, -0.010, -0.002, "Tu-Sa 09:00-17:30", 0.15, 0.35, 0.65, 0.50, nil),
        s(7, "Hub Étudiant", .coworking, 0.002, -0.012, "Mo-Su 08:00-22:00", 0.45, 0.60, 0.90, 0.85, 2.0),
        s(8, "Café Andalous", .cafe, 0.007, 0.007, "Mo-Su 08:00-23:30", 0.65, 0.70, 0.55, 0.40, 2.2),
    ]
    static var live: [String: LiveStats] { Dictionary(uniqueKeysWithValues: spots.map { ($0.id, $0.live) }) }
    static let users: [NookUser] = [
        NookUser(id: "u1", email: "amine@nook.app", pseudo: "Amine", avatarId: 3, xp: 1240, checkins: 61, badges: ["firstCheckIn", "tenCheckIns", "habitue", "maire"]),
        NookUser(id: "u2", email: "sarra@nook.app", pseudo: "Sarra", avatarId: 5, xp: 860, checkins: 40, badges: ["firstCheckIn", "tenCheckIns", "habitue"]),
        NookUser(id: "u3", email: "yassine@nook.app", pseudo: "Yassine", avatarId: 1, xp: 520, checkins: 25, badges: ["firstCheckIn", "tenCheckIns", "habitue"]),
        NookUser(id: "demo", email: "demo@nook.app", pseudo: "Demo", avatarId: 2, xp: 240, checkins: 9, badges: ["firstCheckIn", "earlyBird"]),
        NookUser(id: "u5", email: "meriem@nook.app", pseudo: "Meriem", avatarId: 6, xp: 180, checkins: 8, badges: ["firstCheckIn"]),
        NookUser(id: "u6", email: "karim@nook.app", pseudo: "Karim", avatarId: 4, xp: 60, checkins: 3, badges: ["firstCheckIn"]),
    ]
    static let reviews: [Review] = [
        Review(spotId: "sample-1", uid: "u2", pseudo: "Sarra", rating: 5, comment: "Calme le matin, prises à chaque table !"),
        Review(spotId: "sample-1", uid: "u3", pseudo: "Yassine", rating: 4, comment: "Wi-Fi rapide, café correct."),
        Review(spotId: "sample-2", uid: "u1", pseudo: "Amine", rating: 5, comment: "Le silence parfait pour réviser."),
    ]
}
