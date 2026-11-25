import Foundation
import SwiftData

/// Favori stocké localement (fonctionne hors ligne)
@Model final class FavoriteSpot {
    @Attribute(.unique) var id: String
    var name: String
    var typeRaw: String
    var latitude: Double
    var longitude: Double
    var addedAt: Date

    init(spot: Spot) {
        id = spot.id; name = spot.name; typeRaw = spot.type.rawValue
        latitude = spot.latitude; longitude = spot.longitude; addedAt = .now
    }
    var spot: Spot {
        Spot(id: id, name: name, type: SpotType(rawValue: typeRaw) ?? .cafe, latitude: latitude, longitude: longitude)
    }
}
