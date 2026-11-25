import Foundation
import CoreLocation

enum SpotType: String, Codable, CaseIterable {
    case cafe, library, coworking
    var icon: String {
        switch self {
        case .cafe: return "cup.and.saucer.fill"
        case .library: return "books.vertical.fill"
        case .coworking: return "desktopcomputer"
        }
    }
    var titleKey: String { "type.\(rawValue)" }
}

/// Valeurs 0...1 : noise 0 = silencieux, crowd 0 = vide, wifi 1 = excellent, outlets 1 = nombreuses
struct LiveStats: Codable, Hashable {
    var noise = 0.5, crowd = 0.5, wifi = 0.5, outlets = 0.5
    var coffeePrice: Double?
    var updatedAt = Date.distantPast
    var count = 0

    func merging(_ c: CheckIn) -> LiveStats {
        func mix(_ old: Double, _ new: Int) -> Double {
            let v = Double(new - 1) / 4
            return count == 0 ? v : old * 0.6 + v * 0.4
        }
        var s = self
        s.noise = mix(noise, c.noise); s.crowd = mix(crowd, c.crowd)
        s.wifi = mix(wifi, c.wifi); s.outlets = mix(outlets, c.outlets)
        if let p = c.coffeePrice { s.coffeePrice = coffeePrice.map { $0 * 0.6 + p * 0.4 } ?? p }
        s.updatedAt = c.createdAt; s.count += 1
        return s
    }
    var dict: [String: Any] {
        var d: [String: Any] = ["noise": noise, "crowd": crowd, "wifi": wifi, "outlets": outlets,
                                "updatedAt": updatedAt.timeIntervalSince1970, "count": count]
        if let p = coffeePrice { d["coffeePrice"] = p }
        return d
    }
}
extension LiveStats {
    init?(dict m: [String: Any]) {
        func num(_ k: String) -> Double? { (m[k] as? NSNumber)?.doubleValue }
        guard let n = num("noise"), let c = num("crowd"), let w = num("wifi"), let o = num("outlets") else { return nil }
        self.init(noise: n, crowd: c, wifi: w, outlets: o, coffeePrice: num("coffeePrice"),
                  updatedAt: Date(timeIntervalSince1970: num("updatedAt") ?? 0), count: Int(num("count") ?? 0))
    }
}

struct Spot: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var type: SpotType
    var latitude: Double
    var longitude: Double
    var opening: String?
    var live = LiveStats()

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    func distance(from l: CLLocation?) -> Double? {
        l.map { CLLocation(latitude: latitude, longitude: longitude).distance(from: $0) }
    }
}

enum SpotFilter: String, CaseIterable, Identifiable {
    case quiet, wifi, outlets
    var id: String { rawValue }
    var titleKey: String { "filter.\(rawValue)" }
    var icon: String {
        switch self { case .quiet: return "speaker.slash.fill"; case .wifi: return "wifi"; case .outlets: return "powerplug.fill" }
    }
    func matches(_ s: Spot) -> Bool {
        switch self {
        case .quiet: return s.live.noise <= 0.4
        case .wifi: return s.live.wifi >= 0.6
        case .outlets: return s.live.outlets >= 0.6
        }
    }
}
