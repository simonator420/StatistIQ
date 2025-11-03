import SwiftUI
import FirebaseFirestore
import Combine

final class MatchCardViewModel: ObservableObject {
    @Published var homeId: Int?
    @Published var awayId: Int?
    @Published var startTime: Date?
    @Published var model: MatchModel?
    
    private let scheduleStore = GamesScheduleStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    func bind(gameId: Int) {
        // Fetch immediately if available
        updateValues(for: gameId)
        
        // Listen for store updates
        scheduleStore.$gameMeta
            .combineLatest(scheduleStore.$gameStart)
            .sink { [weak self] _, _ in
                self?.updateValues(for: gameId)
            }
            .store(in: &cancellables)
    }
    
    private func updateValues(for gameId: Int) {
        guard let meta = scheduleStore.gameMeta[gameId] else {
            model = nil
            return
        }

        let start = scheduleStore.gameStart[gameId]
        
        // ✅ Create a MatchModel using the available data
        model = MatchModel(
            id: "\(gameId)",
            gameId: gameId,
            homeId: meta.homeId,
            awayId: meta.awayId,
            startTime: start,
            venue: nil,
            winHome: nil,
            winAway: nil,
            marginFavTeamId: nil,
            marginValue: nil
        )
    }
    
    func stop() {
        cancellables.removeAll()
    }
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

extension MatchModel {
    init(
        id: String,
        gameId: Int,
        homeId: Int?,
        awayId: Int?,
        startTime: Date?,
        venue: String?,
        winHome: Double?,
        winAway: Double?,
        marginFavTeamId: Int?,
        marginValue: Double?
    ) {
        self.id = id
        self.gameId = gameId
        self.homeId = homeId
        self.awayId = awayId
        self.startTime = startTime
        self.venue = venue
        self.winHome = winHome
        self.winAway = winAway
        self.marginFavTeamId = marginFavTeamId
        self.marginValue = marginValue
    }
}

