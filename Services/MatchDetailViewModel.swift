import SwiftUI
import FirebaseFirestore

final class MatchDetailViewModel: ObservableObject {
    @Published var model: MatchDetailModel?
    
    @Published var h2h: [H2HGame] = []
    
    
    @Published var recentHome: [Bool] = []
    @Published var recentAway: [Bool] = []
    @Published var recentReady: Bool = false
    
    func bind(gameId: Int) {
        if let cached = MatchCache.shared.model(for: gameId) {
            self.model = cached
            
            // ✅ Also load recent results if cached
            if let recents = MatchCache.shared.recent(for: gameId) {
                self.recentHome = recents.0
                self.recentAway = recents.1
                self.recentReady = true
            } else {
                // If not cached yet, fetch them now
                self.loadRecentGames(for: cached)
            }
            
            self.fetchHeadToHeadFromGamesPlayed(homeId: cached.homeId, awayId: cached.awayId)
            return
        }
        
        let db = Firestore.firestore()
        recentReady = false
        recentHome = []
        recentAway = []
        
        db.collection("games_schedule")
            .whereField("gameId", isEqualTo: gameId)
            .limit(to: 1)
            .getDocuments { [weak self] snap, _ in
                guard let self = self, let doc = snap?.documents.first else { return }
                let model = MatchDetailModel(doc: doc)
                self.model = model
                MatchCache.shared.store(model)
                self.fetchHeadToHeadFromGamesPlayed(homeId: model.homeId, awayId: model.awayId)
                
                // Fetch recent games once
                self.loadRecentGames(for: model)
            }
    }
    
    private func loadRecentGames(for model: MatchDetailModel) {
        let group = DispatchGroup()
        var recentH: [Bool] = []
        var recentA: [Bool] = []
        
        if let hid = model.homeId {
            group.enter()
            fetchRecentForm(for: hid) { arr in
                recentH = arr
                group.leave()
            }
        }
        
        if let aid = model.awayId {
            group.enter()
            fetchRecentForm(for: aid) { arr in
                recentA = arr
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.recentHome = recentH
            self.recentAway = recentA
            self.recentReady = true
        }
    }
    
    
    
    private func fetchRecentForm(for teamId: Int, assign: @escaping ([Bool]) -> Void) {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var docs: [QueryDocumentSnapshot] = []
        
        group.enter()
        db.collection("games_played")
            .whereField("team_id_home", isEqualTo: teamId)
            .limit(to: 10)
            .getDocuments { snap, _ in
                if let s = snap { docs.append(contentsOf: s.documents) }
                group.leave()
            }
        
        group.enter()
        db.collection("games_played")
            .whereField("team_id_away", isEqualTo: teamId)
            .limit(to:10)
            .getDocuments { snap, _ in
                if let s = snap { docs.append(contentsOf: s.documents) }
                group.leave()
            }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            let mapped: [(Date, Bool)] = docs.compactMap { doc in
                let d = doc.data()
                let date: Date? = {
                    if let ts = d["game_date"] as? Timestamp { return ts.dateValue() }
                    if let s = d["game_date"] as? String { return DateFormatter.gpFormatter.date(from: s) }
                    return nil
                }()
                guard let dt = date else { return nil }
                let isHome = ((d["team_id_home"] as? NSNumber)?.intValue ?? (d["team_id_home"] as? Int)) == teamId
                let isWin: Bool = {
                    if isHome, let wl = d["wl_home"] as? String { return wl.uppercased() == "W" }
                    if !isHome, let wl = d["wl_away"] as? String { return wl.uppercased() == "W" }
                    let ph = (d["pts_home"] as? NSNumber)?.intValue ?? (d["pts_home"] as? Int) ?? 0
                    let pa = (d["pts_away"] as? NSNumber)?.intValue ?? (d["pts_away"] as? Int) ?? 0
                    return isHome ? (ph > pa) : (pa > ph)
                }()
                return (dt, isWin)
            }
            
            let last5 = mapped.sorted(by: { $0.0 > $1.0 }).prefix(5).map { $0.1 }
            assign(Array(last5))
        }
    }
    
    private func fetchHeadToHeadFromGamesPlayed(homeId: Int?, awayId: Int?) {
        guard let h = homeId, let a = awayId else { return }
        let db = Firestore.firestore()
        
        print("H2H fetch for homeId:", h, "awayId:", a)
        
        var allDocs: [QueryDocumentSnapshot] = []
        let group = DispatchGroup()
        
        // A) home=h, away=a
        group.enter()
        db.collection("games_played")
            .whereField("team_id_home", isEqualTo: h)
            .whereField("team_id_away", isEqualTo: a)
            .limit(to: 25)
            .getDocuments { snap, err in
                if let err = err { print("H2H A error:", err.localizedDescription) }
                if let docs = snap?.documents { allDocs.append(contentsOf: docs) }
                group.leave()
            }
        
        // B) home=a, away=h
        group.enter()
        db.collection("games_played")
            .whereField("team_id_home", isEqualTo: a)
            .whereField("team_id_away", isEqualTo: h)
            .limit(to: 25)
            .getDocuments { snap, err in
                if let err = err { print("H2H B error:", err.localizedDescription) }
                if let docs = snap?.documents { allDocs.append(contentsOf: docs) }
                group.leave()
            }
        
        group.notify(queue: .main) {
            let items = allDocs
                .compactMap { H2HGame(doc: $0) }
                .sorted(by: { ($0.startTime ?? .distantPast) > ($1.startTime ?? .distantPast) })
                .prefix(5)
            
            self.h2h = Array(items)
        }
    }
    
    
    func stop() {
        
    }
    
    private static func matchupKey(_ a: Int, _ b: Int) -> String {
        let lo = min(a, b), hi = max(a, b)
        return "\(lo)_\(hi)"
    }
    
}

struct MatchDetailModel {
    let id: String
    let gameId: Int
    let homeId: Int?
    let awayId: Int?
    let startTime: Date?
    let venue: String?
    
    // predictions
    let winHome: Double?
    let winAway: Double?
    let homeMin: Int?
    let homeMax: Int?
    let awayMin: Int?
    let awayMax: Int?
    let expectedMarginValue: Double?
    let expectedMarginTeamId: Int?
    let overtimeProbability: Double?
    
    init(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        id = doc.documentID
        gameId = data["gameId"] as? Int ?? 0
        
        if let teams = data["teams"] as? [String: Any] {
            homeId = teams["homeId"] as? Int
            awayId = teams["awayId"] as? Int
        } else { homeId = nil; awayId = nil }
        
        if let ts = data["startTime"] as? Timestamp {
            startTime = ts.dateValue()
        } else { startTime = nil }
        
        
        venue = data["venue"] as? String
        
        if let predictions = data["predictions"] as? [String: Any] {
            
            if let win = predictions["winProbability"] as? [String: Any] {
                winHome = (win["home"] as? NSNumber)?.doubleValue ?? win["home"] as? Double
                winAway = (win["away"] as? NSNumber)?.doubleValue ?? win["away"] as? Double
            } else { winHome = nil; winAway = nil }
            
            // Overtime probability
            overtimeProbability = (predictions["overtimeProbability"] as? NSNumber)?.doubleValue
            ?? predictions["overtimeProbability"] as? Double
            
            if let pr = predictions["pointsRange"] as? [String: Any],
               let h = pr["home"] as? [String: Any],
               let a = pr["away"] as? [String: Any] {
                homeMin = (h["min"] as? NSNumber)?.intValue ?? h["min"] as? Int
                homeMax = (h["max"] as? NSNumber)?.intValue ?? h["max"] as? Int
                awayMin = (a["min"] as? NSNumber)?.intValue ?? a["min"] as? Int
                awayMax = (a["max"] as? NSNumber)?.intValue ?? a["max"] as? Int
            } else { homeMin = nil; homeMax = nil; awayMin = nil; awayMax = nil }
            
            if let em = predictions["expectedMargin"] as? [String: Any] {
                expectedMarginTeamId = (em["teamId"] as? NSNumber)?.intValue ?? em["teamId"] as? Int
                expectedMarginValue  = (em["value"]  as? NSNumber)?.doubleValue ?? em["value"]  as? Double
            } else { expectedMarginTeamId = nil; expectedMarginValue = nil }
        } else {
            winHome = nil; winAway = nil
            homeMin = nil; homeMax = nil; awayMin = nil; awayMax = nil
            expectedMarginTeamId = nil; expectedMarginValue = nil; overtimeProbability = nil
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
    
    var homeRangeText: String {
        guard let lo = homeMin, let hi = homeMax else { return "–" }
        return "\(lo) - \(hi)"
    }
    
    var awayRangeText: String {
        guard let lo = awayMin, let hi = awayMax else { return "–" }
        return "\(lo) - \(hi)"
    }
    
    func overtimeProbabilityText(using teams: TeamsDirectory) -> String {
        guard let p = overtimeProbability else { return "–" }
        return String(format: "%.1f%%", p)
    }
    
    func expectedMarginText(using teams: TeamsDirectory) -> String {
        guard let val = expectedMarginValue, let tid = expectedMarginTeamId else { return "–" }
        let name = teams.team(tid)?.name ?? "Team"
        let sign = val >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", val)) \(name)"
    }
}


struct H2HGame: Identifiable {
    let id: String
    let homeId: Int
    let awayId: Int
    let homeScore: Int?
    let awayScore: Int?
    let startTime: Date?
    let venue: String? // your games_played sample doesn’t show venue; keep optional
    
    init?(doc: QueryDocumentSnapshot) {
        let d = doc.data()
        
        guard
            let h = (d["team_id_home"] as? NSNumber)?.intValue ?? (d["team_id_home"] as? Int),
            let a = (d["team_id_away"] as? NSNumber)?.intValue ?? (d["team_id_away"] as? Int)
        else { return nil }
        
        id = doc.documentID
        homeId = h
        awayId = a
        homeScore = (d["pts_home"] as? NSNumber)?.intValue ?? (d["pts_home"] as? Int)
        awayScore = (d["pts_away"] as? NSNumber)?.intValue ?? (d["pts_away"] as? Int)
        
        // game_date is a string "YYYY-MM-DD HH:mm:ss"
        if let s = d["game_date"] as? String {
            startTime = DateFormatter.gpFormatter.date(from: s)
        } else {
            startTime = nil
        }
        
        venue = d["venue"] as? String // only if you store it there
    }
}

private extension DateFormatter {
    static let gpFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0) // adjust if your strings are local time
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}
