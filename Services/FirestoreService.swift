import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()
    
    func saveTeams(_ teams: [Team]) {
        let teamsRef = db.collection("teams")
        for team in teams {
            teamsRef.document("\(team.id)").setData([
                "name": team.name,
                "code": team.code ?? "",
                "logo": team.logo ?? "",
                "country": team.country ?? "",
                "nba_team": true
            ])
        }
    }
}
