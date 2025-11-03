final class MatchCache {
    static let shared = MatchCache()
    private init() {}
    
    private var modelCache: [Int: MatchDetailModel] = [:]
    private var recentCache: [Int: ([Bool], [Bool])] = [:]
    
    func model(for id: Int) -> MatchDetailModel? {
        modelCache[id]
    }
    
    func store(_ model: MatchDetailModel) {
        modelCache[model.gameId] = model
    }
    
    func recent(for id: Int) -> ([Bool], [Bool])? {
        recentCache[id]
    }
    
    func storeRecent(for id: Int, home: [Bool], away: [Bool]) {
        recentCache[id] = (home, away)
    }
    
    func clear() {
        modelCache.removeAll()
        recentCache.removeAll()
    }
}
