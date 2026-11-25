import Foundation

/// Réponse Open-Meteo : /v1/forecast?current=temperature_2m,weather_code,wind_speed_10m,precipitation
struct WeatherInfo: Decodable {
    struct Current: Decodable {
        let temperature: Double
        let code: Int
        let wind: Double
        let precipitation: Double
        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m", code = "weather_code", wind = "wind_speed_10m", precipitation
        }
    }
    let current: Current

    var symbol: String {
        switch current.code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "snowflake"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
    /// Terrasse agréable ? (18-30 °C, pas de pluie, vent modéré)
    var terraceOK: Bool {
        (18...30).contains(current.temperature) && current.precipitation == 0 && current.wind < 25 && current.code < 51
    }
}
