import FirebaseFirestore

final class TeamsDirectory: ObservableObject {
    static let shared = TeamsDirectory()
    @Published private(set) var teams: [Int: FirebaseTeam] = [:]
    @Published private(set) var isLoaded: Bool = false
    
    private let db = Firestore.firestore()
    
    func loadIfNeeded() {
        guard !isLoaded else { return }
        if !teams.isEmpty { return }
        db.collection("teams").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { return }
            
            var map: [Int: FirebaseTeam] = [:]
            for doc in docs {
                // Your doc IDs are "152", "1610612737", etc.
                guard let id = Int(doc.documentID) else { continue }
                let data = doc.data()
                
                // Build FirebaseTeam from fields you store
                guard let name = data["name"] as? String,
                      let abbreviation = data["abbreviation"] as? String,
                      let country = data["country"] as? String,
                      let nbaTeam = data["nba_team"] as? Bool,
                      let arena = data["arena"] as? String,
                      let city  = data["city"]  as? String else { continue }
                
                let code = data["code"] as? String ?? ""
                let logo = data["logo"] as? String
                
                let primaryColor = data["primaryColor"] as? String
                let secondaryColor = data["secondaryColor"] as? String
                
                map[id] = FirebaseTeam(id: id,
                                       name: name,
                                       code: code,
                                       logo: logo,
                                       country: country,
                                       abbreviation: abbreviation,
                                       nba_team: nbaTeam,
                                       arena: arena,
                                       city: city,
                                       primaryColor: primaryColor,
                                       secondaryColor: secondaryColor
                )
            }
            DispatchQueue.main.async {
                self.teams = map
                self.isLoaded = true
            }
        }
    }
    
    func team(_ id: Int) -> FirebaseTeam? { teams[id] }
    func arena(for id: Int) -> String? { teams[id]?.arena }
    func city(for id: Int)  -> String? { teams[id]?.city }
    func abbreviation(for id: Int) -> String? { teams[id]?.abbreviation }
    func code(for id: Int) -> String? { teams[id]?.code }
}
