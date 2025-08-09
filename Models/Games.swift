import Foundation

struct GameResponse: Codable {
    let response: [Game]
}

struct Game: Codable, Identifiable {
    let id: Int
    let date: String
    let time: String?
    let timestamp: Int?
    let teams: GameTeams
    let scores: GameScores
}

struct GameTeams: Codable {
    let home: GameTeam
    let away: GameTeam
}

struct GameTeam: Codable {
    let id: Int
    let name: String
    let logo: String?
}

struct GameScores: Codable {
    let home: Int?
    let away: Int?
}

struct StatsResponse: Codable {
    let response: [TeamStats]
}

struct TeamStats: Codable {
    let team: GameTeam
    let statistics: [Stat]
}

struct Stat: Codable {
    let type: String
    let value: String?
}


