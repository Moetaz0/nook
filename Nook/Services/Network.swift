import Foundation

struct APIClient {
    var session: URLSession = .shared

    func get<T: Decodable>(_ url: URL) async throws -> T {
        var r = URLRequest(url: url); r.timeoutInterval = 15
        return try await send(r)
    }
    func post<T: Decodable>(_ url: URL, form: String) async throws -> T {
        var r = URLRequest(url: url)
        r.httpMethod = "POST"; r.httpBody = form.data(using: .utf8); r.timeoutInterval = 10
        r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await send(r)
    }
    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        var r = request
        r.setValue("Nook-iOS/1.0 (student project)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, resp) = try await session.data(for: r)
            if let h = resp as? HTTPURLResponse, !(200..<300).contains(h.statusCode) { throw AppError.server(h.statusCode) }
            do { return try JSONDecoder().decode(T.self, from: data) } catch { throw AppError.decoding }
        } catch let e as AppError { throw e } catch { throw AppError.network }
    }
}

/// Overpass API (OpenStreetMap) : cafés, bibliothèques, espaces de coworking autour d'un point. Sans clé.
struct OverpassService {
    private struct Response: Decodable {
        struct Element: Decodable { let id: Int; let lat: Double?; let lon: Double?; let tags: [String: String]? }
        let elements: [Element]
    }
    var api = APIClient()

    func nearby(lat: Double, lon: Double, radius: Int = 1000) async throws -> [Spot] {
        let around = "(around:\(radius),\(lat),\(lon))"
        let query = """
        [out:json][timeout:10];
        (node["amenity"="cafe"]\(around);
         node["amenity"="library"]\(around);
         node["office"="coworking"]\(around);
         node["amenity"="coworking_space"]\(around););
        out body 40;
        """
        let enc = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let endpoints = ["https://overpass-api.de/api/interpreter",
                         "https://overpass.kumi.systems/api/interpreter",
                         "https://overpass.private.coffee/api/interpreter"]
        var lastError: Error = AppError.network
        var found: Response?
        for ep in endpoints {
            do { found = try await api.post(URL(string: ep)!, form: "data=" + enc); break } catch { lastError = error }
        }
        guard let r = found else { throw lastError }
        return r.elements.compactMap { e in
            guard let lat = e.lat, let lon = e.lon, let tags = e.tags, let name = tags["name"] else { return nil }
            let type: SpotType = tags["amenity"] == "library" ? .library
                : (tags["office"] == "coworking" || tags["amenity"] == "coworking_space") ? .coworking : .cafe
            var live = LiveStats()
            if ["wlan", "wifi", "yes"].contains(tags["internet_access"] ?? "") { live.wifi = 0.7 }
            return Spot(id: "osm-\(e.id)", name: name, type: type, latitude: lat, longitude: lon,
                        opening: tags["opening_hours"], live: live)
        }
    }
}

/// Open-Meteo : météo actuelle (terrasse ou intérieur ?). Sans clé.
struct WeatherService {
    var api = APIClient()
    func current(lat: Double, lon: Double) async throws -> WeatherInfo {
        let u = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code,wind_speed_10m,precipitation"
        return try await api.get(URL(string: u)!)
    }
}
