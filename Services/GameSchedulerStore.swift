import SwiftUI
import FirebaseFirestore

final class GamesScheduleStore: ObservableObject {
    static let shared = GamesScheduleStore()
    
    @Published var gameIds: [Int] = []
    @Published var gameMeta: [Int: (homeId: Int, awayId: Int)] = [:]
    @Published var gameStart: [Int: Date] = [:]
    @Published var refreshPulse = UUID()
    
    @Published var isLoading: Bool = false
    private var listener: ListenerRegistration?
    
    private init() {}
    
    private func asInt(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        return nil
    }
    
    private func handleSnapshot(_ docs: [QueryDocumentSnapshot]) {
        var ids: [Int] = []
        var meta: [Int: (Int, Int)] = [:]
        var starts: [Int: Date] = [:]
        
        for doc in docs {
            let d = doc.data()
            guard let gid = asInt(d["gameId"]) else { continue }
            ids.append(gid)
            
            if let teams = d["teams"] as? [String: Any],
               let h = asInt(teams["homeId"]),
               let a = asInt(teams["awayId"]) {
                meta[gid] = (h, a)
            } else if let h = asInt(d["team_id_home"]),
                      let a = asInt(d["team_id_away"]) {
                meta[gid] = (h, a)
            }
            
            if let ts = d["startTime"] as? Timestamp {
                starts[gid] = ts.dateValue()
            }
        }
        
        DispatchQueue.main.async {
            self.gameIds = ids
            self.gameMeta = meta
            self.gameStart = starts
        }
    }
    
    func start() {
        if listener != nil { return }
        // Show spinner only if we have no cache yet.
        isLoading = gameIds.isEmpty
        
        let db = Firestore.firestore()
        let now = Date()
        
        // Fetch games from 3 hours ago to 48 hours in the future
        let pastWindow = now.addingTimeInterval(-10_800) // 3 hours ago
        let futureWindow = now.addingTimeInterval(172_800) // 48 hours ahead
        
        db.collection("games_schedule")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: pastWindow))
            .whereField("startTime", isLessThanOrEqualTo: Timestamp(date: futureWindow))
            .order(by: "startTime")
            .getDocuments { [weak self] snap, _ in
                guard let self = self else { return }
                self.isLoading = false
                guard let docs = snap?.documents else { return }
                self.handleSnapshot(docs)
            }
    }
    
    func stop() {
        listener?.remove()
        listener = nil
    }
    
    deinit { listener?.remove() }
}
