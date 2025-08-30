import SwiftUI
import FirebaseFirestore

final class MatchCardViewModel: ObservableObject {
    @Published var model: MatchModel?
    private var listener: ListenerRegistration?
    private let teamsDirectory = TeamsDirectory.shared
    
    func bind(gameId: Int) {
        let db = Firestore.firestore()
        listener?.remove()
        listener = db.collection("games_schedule")
            .whereField("gameId", isEqualTo: gameId)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self, let doc = snap?.documents.first else { return }
                self.model = MatchModel(doc: doc)
            }
    }
    
    func stop() {
        listener?.remove()
        listener = nil
    }
    
    deinit { listener?.remove() }
}

struct MatchModel {
    let id: String
    let gameId: Int
    let homeId: Int?
    let awayId: Int?
    let startTime: Date?
    var venue: String?
    let winHome: Double?
    let winAway: Double?
    let marginFavTeamId: Int?
    let marginValue: Double?
    
    init(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        id = doc.documentID
        gameId = data["gameId"] as? Int ?? 0
        
        // teams.homeId / awayId
        if let teams = data["teams"] as? [String: Any] {
            homeId = teams["homeId"] as? Int
            awayId = teams["awayId"] as? Int
        } else {
            homeId = nil
            awayId = nil
        }
        
        // startTime
        if let ts = data["startTime"] as? Timestamp {
            startTime = ts.dateValue()
        } else {
            startTime = nil
        }
        
        venue = data["venue"] as? String
        
        // predictions.winProbability.home/away
        if let predictions = data["predictions"] as? [String: Any],
           let winProb = predictions["winProbability"] as? [String: Any] {
            winHome = (winProb["home"] as? NSNumber)?.doubleValue ?? winProb["home"] as? Double
            winAway = (winProb["away"] as? NSNumber)?.doubleValue ?? winProb["away"] as? Double
        } else {
            winHome = nil
            winAway = nil
        }
        
        if let em = (data["predictions"] as? [String: Any])?["expectedMargin"] as? [String: Any] {
            let fav = em["teamId"] as? NSNumber
            marginFavTeamId = fav?.intValue ?? em["teamId"] as? Int
            marginValue = (em["value"] as? NSNumber)?.doubleValue ?? em["value"] as? Double
        } else {
            marginFavTeamId = nil
            marginValue = nil
        }
    }
    
    var homeWinText: String {
        guard let w = winHome else { return "-" }
        return "\(Int((w * 100).rounded()))%"
    }
    var awayWinText: String {
        guard let w = winAway else { return "-" }
        return "\(Int((w * 100).rounded()))%"
    }
    
    // Set as venue row from firestore
    func timeAndVenue(start: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        var s = df.string(from: start)
        if let v = venue, !v.isEmpty { s += "  •  \(v)" }
        return s
    }
}
