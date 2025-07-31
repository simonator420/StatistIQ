import Foundation

struct Team: Codable, Identifiable {
    let id: Int
    let name: String
    let code: String?
    let logo: String?
    let country: String?
}
