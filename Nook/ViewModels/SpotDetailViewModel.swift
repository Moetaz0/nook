import Foundation
import Observation

@MainActor @Observable final class SpotDetailViewModel {
    var weather: LoadState<WeatherInfo> = .idle
    var reviews: LoadState<[Review]> = .idle

    func load(spot: Spot, data: DataService) async {
        weather = .loading
        reviews = .loading
        async let w = WeatherService().current(lat: spot.latitude, lon: spot.longitude)   // chargement en parallèle
        async let r = data.reviews(for: spot.id)
        do { weather = .loaded(try await w) } catch { weather = .failed(AppError.key(for: error)) }
        do { let l = try await r; reviews = l.isEmpty ? .empty : .loaded(l) } catch { reviews = .failed(AppError.key(for: error)) }
    }

    func reloadReviews(spot: Spot, data: DataService) async {
        do { let l = try await data.reviews(for: spot.id); reviews = l.isEmpty ? .empty : .loaded(l) }
        catch { reviews = .failed(AppError.key(for: error)) }
    }
}
