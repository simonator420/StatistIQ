import SwiftUI
import FirebaseFirestore

final class GamesScheduleStore: ObservableObject {
    @Published var gameIds: [Int] = []
    @Published var gameMeta: [Int: (homeId: Int, awayId: Int)] = [:]
    
    @Published var isLoading: Bool = false
    private var listener: ListenerRegistration?
    
    private func asInt(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        return nil
    }
    
    private func handleSnapshot(_ docs: [QueryDocumentSnapshot]) {
        var ids: [Int] = []
        var meta: [Int: (Int, Int)] = [:]
        
        for doc in docs {
            let d = doc.data()
            guard let gid = asInt(d["gameId"]) else { continue }
            ids.append(gid)
            
            if let teams = d["teams"] as? [String: Any],
               let h = asInt(teams["homeId"]),
               let a = asInt(teams["awayId"]) {
                meta[gid] = (h, a)
            } else if let h = asInt(d["team_id_home"]),   // optional fallback
                      let a = asInt(d["team_id_away"]) {
                meta[gid] = (h, a)
            }
        }
        
        DispatchQueue.main.async {
            self.gameIds = ids
            self.gameMeta = meta
        }
    }
    
    func start() {
        let db = Firestore.firestore()
        listener?.remove()
        isLoading = true
        
        listener = db.collection("games_schedule")
            .whereField("startTime", isGreaterThan: Timestamp(date: Date()))
            .order(by: "startTime")
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self else { return }
                self.isLoading = false
                guard let docs = snap?.documents else {
                    self.gameIds = []
                    self.gameMeta = [:]
                    return
                }
                self.handleSnapshot(docs)
            }
    }
    
    
    deinit {
        listener?.remove()
    }
}
