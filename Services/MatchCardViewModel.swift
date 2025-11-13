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
    private var predictionListener: ListenerRegistration?

    
    func bind(gameId: Int) {

        updateValues(for: gameId)

        // Listen for schedule updates
        scheduleStore.$gameMeta
            .combineLatest(scheduleStore.$gameStart)
            .sink { [weak self] meta, start in
                self?.updateValues(for: gameId)
            }
            .store(in: &cancellables)

        predictionListener?.remove()

        predictionListener = Firestore.firestore()
            .collection("games_schedule")
            .document("\(gameId)")
            .addSnapshotListener { [weak self] snap, err in

                if let err = err {
                    print("Predictions error for \(gameId):", err)
                    return
                }

                guard let snap = snap,
                      let data = snap.data()
                else {
                    print("No schedule doc for \(gameId)")
                    return
                }

                // Parse predictions
                if let predictions = data["predictions"] as? [String: Any] {
                    let win = predictions["winProbability"] as? [String: Any]
                    let em  = predictions["expectedMargin"] as? Double

                    let winHome = win?["home"] as? Double
                    let winAway = win?["away"] as? Double

                    // Merge into existing model
                    if var current = self?.model {
                        current.winHome = winHome
                        current.winAway = winAway
                        current.marginValue = em
                        current.marginFavTeamId = nil
                        self?.model = current
                    }
                }
            }
    }

    
    private func updateValues(for gameId: Int) {
        guard let meta = scheduleStore.gameMeta[gameId] else {
            model = nil
            return
        }

        let start = scheduleStore.gameStart[gameId]
        
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
        predictionListener?.remove()
        predictionListener = nil
    }
}

struct MatchModel {
    let id: String
    let gameId: Int
    let homeId: Int?
    let awayId: Int?
    let startTime: Date?
    var venue: String?
    var winHome: Double?
    var winAway: Double?
    var marginFavTeamId: Int?
    var marginValue: Double?
    
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
    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        
        id = doc.documentID
        gameId = data["gameId"] as? Int ?? 0
        
        if let teams = data["teams"] as? [String: Any] {
            homeId = teams["homeId"] as? Int
            awayId = teams["awayId"] as? Int
        } else {
            homeId = nil
            awayId = nil
        }
        
        if let ts = data["startTime"] as? Timestamp {
            startTime = ts.dateValue()
        } else {
            startTime = nil
        }
        
        venue = data["venue"] as? String
        
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

