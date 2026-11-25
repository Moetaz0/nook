import Foundation
import CoreLocation
import Observation

@MainActor @Observable final class ExplorerViewModel {
    var state: LoadState<[Spot]> = .idle
    var filters: Set<SpotFilter> = []
    private(set) var all: [Spot] = []
    private(set) var center: CLLocation?

    @ObservationIgnored private var base: [Spot] = []      // Overpass (ou données d'exemple en secours)
    @ObservationIgnored private var custom: [Spot] = []    // spots ajoutés par les utilisateurs
    @ObservationIgnored private var liveCache: [String: LiveStats] = [:]
    @ObservationIgnored private var cancels: [() -> Void] = []
    @ObservationIgnored private let overpass = OverpassService()
    @ObservationIgnored private let data: DataService

    init(data: DataService) {
        self.data = data
        // Temps réel : jauges + spots ajoutés par la communauté
        cancels.append(data.observeLive { [weak self] d in
            self?.liveCache = d
            self?.rebuild()
        })
        cancels.append(data.observeCustomSpots { [weak self] list in
            self?.custom = list
            self?.rebuild()
        })
    }

    var filtered: [Spot] {
        all.filter { s in filters.allSatisfy { $0.matches(s) } }
            .sorted { ($0.distance(from: center) ?? .greatestFiniteMagnitude) < ($1.distance(from: center) ?? .greatestFiniteMagnitude) }
    }

    func spot(id: String) -> Spot? { all.first { $0.id == id } }

    func loadIfNeeded(location: CLLocation?) async {
        if case .idle = state { await load(location: location) }
    }

    func load(location: CLLocation?) async {
        let loc = location ?? CLLocation(latitude: AppConfig.defaultCoordinate.latitude, longitude: AppConfig.defaultCoordinate.longitude)
        center = loc
        if all.isEmpty { state = .loading }
        do {
            base = try await overpass.nearby(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        } catch {
            base = SampleData.spots          // secours : données d'exemple si l'API est injoignable
        }
        rebuild()
    }

    /// Ajout immédiat (le listener Firestore confirmera ensuite)
    func add(_ spot: Spot) {
        if center == nil {
            center = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        }
        custom.removeAll { $0.id == spot.id }
        custom.insert(spot, at: 0)
        rebuild()
    }

    func locationUpdated(_ l: CLLocation) async {
        if let c = center, c.distance(from: l) < 500 { return }
        if case .loading = state { return }
        await load(location: l)
    }

    private func rebuild() {
        let scopedCustom: [Spot]
        if let c = center {
            scopedCustom = custom.filter { ($0.distance(from: c) ?? 0) < 25_000 }
        } else {
            scopedCustom = custom
        }

        var seen = Set<String>()
        var list: [Spot] = []
        // Les spots personnalisés en premier pour apparaître immédiatement sur ExplorerView
        for s0 in scopedCustom + base where seen.insert(s0.id).inserted {
            var s = s0
            if let l = liveCache[s.id] { s.live = l }
            list.append(s)
        }
        all = list
        state = list.isEmpty ? .empty : .loaded(list)
    }
}
