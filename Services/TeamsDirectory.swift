import Foundation

final class TeamsDirectory: ObservableObject {
    static let shared = TeamsDirectory()
    
    @Published private(set) var byId: [Int: Team] = [:]
    private let api = APIService()
    private var isLoading = false
    
    func loadIfNeeded() {
        guard !isLoading, byId.isEmpty else { return }
        isLoading = true
        api.fetchTeams { [weak self] teams in
            DispatchQueue.main.async {
                self?.byId = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0) })
                self?.isLoading = false
            }
        }
    }
    
    func team(_ id: Int) -> Team? {
        byId[id]
    }
}
