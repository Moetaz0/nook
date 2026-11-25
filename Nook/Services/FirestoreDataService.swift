#if canImport(FirebaseFirestore)
import Foundation
import FirebaseFirestore

/// Collections : spots, checkins, reviews, users, usernames, users/{uid}/favorites
@MainActor final class FirestoreDataService: DataService {
    private let db = Firestore.firestore()   // cache hors ligne activé par défaut sur iOS

    func observeLive(_ onChange: @escaping ([String: LiveStats]) -> Void) -> () -> Void {
        let l = db.collection("spots").addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            var out: [String: LiveStats] = [:]
            for d in docs {
                if let m = d.data()["live"] as? [String: Any], let s = LiveStats(dict: m) { out[d.documentID] = s }
            }
            Task { @MainActor in onChange(out) }
        }
        return { l.remove() }
    }

    func submit(_ c: CheckIn, spot: Spot) async throws {
        let ref = db.collection("spots").document(spot.id)
        var live = spot.live
        if let snap = try? await ref.getDocument(), let m = snap.data()?["live"] as? [String: Any], let s = LiveStats(dict: m) { live = s }
        let newLive = live.merging(c)
        try await ref.setData(["name": spot.name, "type": spot.type.rawValue, "lat": spot.latitude,
                               "lng": spot.longitude, "live": newLive.dict], merge: true)
        try await db.collection("checkins").document(c.id).setData(c.dict)
        if !c.comment.isEmpty {
            try await db.collection("reviews").document(c.id).setData(
                ["spotId": spot.id, "uid": c.uid, "pseudo": c.pseudo, "rating": c.rating,
                 "comment": c.comment, "createdAt": c.createdAt])
        }
    }

    func reviews(for spotId: String) async throws -> [Review] {
        let snap = try await db.collection("reviews").whereField("spotId", isEqualTo: spotId).limit(to: 30).getDocuments()
        return snap.documents.map { d in
            let m = d.data()
            return Review(id: d.documentID, spotId: spotId, uid: m["uid"] as? String ?? "", pseudo: m["pseudo"] as? String ?? "Nooker",
                          rating: m["rating"] as? Int ?? 0, comment: m["comment"] as? String ?? "",
                          createdAt: (m["createdAt"] as? Timestamp)?.dateValue() ?? .now)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    private func decode(_ id: String, _ m: [String: Any]) -> NookUser {
        NookUser(id: id, email: m["email"] as? String ?? "", pseudo: m["pseudo"] as? String ?? "Nooker",
                 avatarId: m["avatarId"] as? Int ?? 0, xp: m["xp"] as? Int ?? 0, checkins: m["checkins"] as? Int ?? 0,
                 badges: m["badges"] as? [String] ?? [], isPlus: m["isPlus"] as? Bool ?? false)
    }
    func user(uid: String) async throws -> NookUser? {
        let d = try await db.collection("users").document(uid).getDocument()
        return d.data().map { decode(uid, $0) }
    }
    func createUser(_ u: NookUser) async throws {
        let batch = db.batch()
        batch.setData(u.dict, forDocument: db.collection("users").document(u.id))
        batch.setData(["uid": u.id], forDocument: db.collection("usernames").document(u.pseudo.lowercased()))
        try await batch.commit()
    }
    func updateUser(_ u: NookUser) async throws { try await db.collection("users").document(u.id).setData(u.dict, merge: true) }
    func leaderboard() async throws -> [NookUser] {
        let snap = try await db.collection("users").order(by: "xp", descending: true).limit(to: 10).getDocuments()
        return snap.documents.map { decode($0.documentID, $0.data()) }
    }
    func isPseudoAvailable(_ p: String) async -> Bool {
        let d = try? await db.collection("usernames").document(p.lowercased()).getDocument()
        return !(d?.exists ?? false)
    }
    func setFavorite(uid: String, spot: Spot, isFavorite: Bool) async throws {
        let ref = db.collection("users").document(uid).collection("favorites").document(spot.id)
        if isFavorite {
            try await ref.setData(["name": spot.name, "type": spot.type.rawValue, "lat": spot.latitude,
                                   "lng": spot.longitude, "addedAt": Date()])
        } else { try await ref.delete() }
    }
}
#endif
