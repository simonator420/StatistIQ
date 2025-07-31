import Foundation

class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    private let apiService = APIService()
    private let firestoreService = FirestoreService()
    
    func loadTeams() {
        apiService.fetchTeams { [weak self] teams in
            DispatchQueue.main.async {
                self?.teams = teams
                self?.firestoreService.saveTeams(teams)
                print("✅ Týmy byly načteny a uloženy do Firestore!")
            }
        }
    }
}
