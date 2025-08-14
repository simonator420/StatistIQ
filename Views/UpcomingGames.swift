import FirebaseFirestore
import Combine


struct UpcomingCardData: Identifiable {
    let id: Int            // gameId
    let start: Date
    let venue: String
    let homeId: Int
    let awayId: Int
    let homeProb: Double
    let awayProb: Double
}

extension UpcomingCardData {
    init?(doc: DocumentSnapshot) {
        let d = doc.data() ?? [:]

        // Helper to read Int that might be stored as Int / Int64 / NSNumber
        func readInt(_ any: Any?) -> Int? {
            switch any {
            case let x as Int: return x
            case let x as Int64: return Int(x)
            case let x as NSNumber: return x.intValue
            case let s as String: return Int(s)
            default: return nil
            }
        }

        guard
            let gameId = readInt(d["gameId"]),
            let ts = d["startTime"] as? Timestamp,
            let teams = d["teams"] as? [String: Any],
            let homeId = readInt(teams["homeId"]),
            let awayId = readInt(teams["awayId"])
        else { return nil }
        
        let venue = d["venue"] as? String ?? ""
        var homeProb = 0.0, awayProb = 0.0
        if let predictions = d["predictions"] as? [String: Any],
           let win = predictions["winProbability"] as? [String: Any] {
            homeProb = (win["home"] as? Double) ?? 0
            awayProb = (win["away"] as? Double) ?? 0
        }
        self.id = gameId
        self.start = ts.dateValue()
        self.venue = venue
        self.homeId = homeId
        self.awayId = awayId
        self.homeProb = homeProb
        self.awayProb = awayProb
    }
}

final class UpcomingGamesVM: ObservableObject {
    @Published var cards: [UpcomingCardData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var listener: ListenerRegistration?
    private let teamsDirectory = TeamsDirectory.shared
    
    deinit { listener?.remove() }
    
    func start() {
        // Ensure teams are loaded so abbreviations/logos are ready
        teamsDirectory.loadIfNeeded()
        
        listener?.remove()
        isLoading = true
        error = nil
        
        let db = Firestore.firestore()
        let nowTs = Timestamp(date: Date())
        
        listener = db.collection("games_schedule")
            .whereField("startTime", isGreaterThanOrEqualTo: nowTs)
            .order(by: "startTime", descending: false)
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self else { return }
                if let err = err {
                    self.error = err.localizedDescription
                    self.isLoading = false
                    return
                }
                self.cards = (snap?.documents ?? []).compactMap(UpcomingCardData.init(doc:))
                self.isLoading = false
            }
    }
    
    // Convenience passthroughs for the view (Firebase-only)
    func team(_ id: Int) -> FirebaseTeam? { teamsDirectory.team(id) }
    func abbreviation(for id: Int) -> String? { teamsDirectory.abbreviation(for: id) }

}
