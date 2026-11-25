import Foundation

struct CheckIn: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var spotId: String
    var uid: String
    var pseudo: String
    var noise: Int, crowd: Int, wifi: Int, outlets: Int   // 1...5
    var coffeePrice: Double?
    var rating: Int                                        // 1...5
    var comment: String
    var createdAt = Date()

    var dict: [String: Any] {
        var d: [String: Any] = ["id": id, "spotId": spotId, "uid": uid, "pseudo": pseudo, "noise": noise, "crowd": crowd,
                                "wifi": wifi, "outlets": outlets, "rating": rating, "comment": comment, "createdAt": createdAt]
        if let p = coffeePrice { d["coffeePrice"] = p }
        return d
    }
}

struct Review: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var spotId: String
    var uid: String
    var pseudo: String
    var rating: Int
    var comment: String
    var createdAt = Date()
}
