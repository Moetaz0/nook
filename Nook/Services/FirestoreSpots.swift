#if canImport(FirebaseFirestore)
import Foundation
import FirebaseFirestore

extension FirestoreDataService {
    func addSpot(_ s: Spot, uid: String) async throws {
        try await Firestore.firestore().collection("spots").document(s.id).setData(
            ["name": s.name, "type": s.type.rawValue, "lat": s.latitude, "lng": s.longitude,
             "opening": s.opening ?? "", "custom": true, "createdBy": uid, "createdAt": Date()], merge: true)
    }

    func observeCustomSpots(_ onChange: @escaping ([Spot]) -> Void) -> () -> Void {
        let l = Firestore.firestore().collection("spots").whereField("custom", isEqualTo: true).addSnapshotListener { snap, _ in
            guard let docs = snap?.documents else { return }
            let list: [Spot] = docs.compactMap { d in
                let m = d.data()
                guard let name = m["name"] as? String,
                      let lat = (m["lat"] as? NSNumber)?.doubleValue,
                      let lng = (m["lng"] as? NSNumber)?.doubleValue else { return nil }
                let type = SpotType(rawValue: m["type"] as? String ?? "") ?? .cafe
                let hours = (m["opening"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                var live = LiveStats()
                if let lm = m["live"] as? [String: Any], let s = LiveStats(dict: lm) { live = s }
                return Spot(id: d.documentID, name: name, type: type, latitude: lat, longitude: lng, opening: hours, live: live)
            }
            Task { @MainActor in onChange(list) }
        }
        return { l.remove() }
    }
}
#endif
