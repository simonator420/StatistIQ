import Foundation

struct Team: Identifiable, Codable {
    let id: Int
    let name: String
    let code: String
    let logo: String?
    let country: String
}

struct FirebaseTeam: Identifiable, Codable {
    let id: Int
    let name: String
    let code: String
    let logo: String?
    let country: String
    let abbreviation: String
    let nba_team: Bool
    let arena: String?
    let city: String?
    let primaryColor: String?
    let secondaryColor: String?
}
