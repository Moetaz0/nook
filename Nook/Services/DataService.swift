import Foundation

@MainActor protocol DataService: AnyObject {
    func observeLive(_ onChange: @escaping ([String: LiveStats]) -> Void) -> () -> Void
    func observeCustomSpots(_ onChange: @escaping ([Spot]) -> Void) -> () -> Void
    func addSpot(_ spot: Spot, uid: String) async throws
    func submit(_ c: CheckIn, spot: Spot) async throws
    func reviews(for spotId: String) async throws -> [Review]
    func user(uid: String) async throws -> NookUser?
    func createUser(_ u: NookUser) async throws
    func updateUser(_ u: NookUser) async throws
    func leaderboard() async throws -> [NookUser]
    func isPseudoAvailable(_ p: String) async -> Bool
    func setFavorite(uid: String, spot: Spot, isFavorite: Bool) async throws
}

/// Implémentation en mémoire : l'app fonctionne et se démontre sans Firebase.
@MainActor final class MockDataService: DataService {
    private var live = SampleData.live
    private var reviewList = SampleData.reviews
    private var users = Dictionary(uniqueKeysWithValues: SampleData.users.map { ($0.id, $0) })
    private var customSpots: [Spot] = []
    private var observers: [UUID: ([String: LiveStats]) -> Void] = [:]
    private var spotObservers: [UUID: ([Spot]) -> Void] = [:]

    func observeLive(_ onChange: @escaping ([String: LiveStats]) -> Void) -> () -> Void {
        let id = UUID(); observers[id] = onChange; onChange(live)
        return { [weak self] in self?.observers[id] = nil }
    }
    func observeCustomSpots(_ onChange: @escaping ([Spot]) -> Void) -> () -> Void {
        let id = UUID(); spotObservers[id] = onChange; onChange(customSpots)
        return { [weak self] in self?.spotObservers[id] = nil }
    }
    func addSpot(_ spot: Spot, uid: String) async throws {
        try await Task.sleep(for: .milliseconds(400))
        customSpots.append(spot)
        spotObservers.values.forEach { $0(customSpots) }
    }
    func submit(_ c: CheckIn, spot: Spot) async throws {
        try await Task.sleep(for: .milliseconds(500))
        live[spot.id] = (live[spot.id] ?? spot.live).merging(c)
        if !c.comment.isEmpty {
            reviewList.insert(Review(spotId: spot.id, uid: c.uid, pseudo: c.pseudo, rating: c.rating, comment: c.comment), at: 0)
        }
        observers.values.forEach { $0(live) }
    }
    func reviews(for spotId: String) async throws -> [Review] {
        try await Task.sleep(for: .milliseconds(300))
        return reviewList.filter { $0.spotId == spotId }
    }
    func user(uid: String) async throws -> NookUser? { users[uid] }
    func createUser(_ u: NookUser) async throws { users[u.id] = u }
    func updateUser(_ u: NookUser) async throws { users[u.id] = u }
    func leaderboard() async throws -> [NookUser] {
        try await Task.sleep(for: .milliseconds(400))
        return users.values.sorted { $0.xp > $1.xp }.prefix(10).map { $0 }
    }
    func isPseudoAvailable(_ p: String) async -> Bool { !users.values.contains { $0.pseudo.lowercased() == p.lowercased() } }
    func setFavorite(uid: String, spot: Spot, isFavorite: Bool) async throws {}
}
