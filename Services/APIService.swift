import Foundation

class APIService {
    private let apiKey = "5a3136f0a1msh576a27a79435a81p1dbe71jsn352b90bfa903"
    private let host = "api-basketball.p.rapidapi.com"
    
    func fetchTeams(completion: @escaping ([Team]) -> Void) {
        var components = URLComponents(string: "https://api-basketball.p.rapidapi.com/teams")!
        components.queryItems = [
            URLQueryItem(name: "league", value: "12"),
            URLQueryItem(name: "season", value: "2024-2025")
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue(host, forHTTPHeaderField: "X-RapidAPI-Host")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                let teams = response.response.map { apiTeam in
                    Team(
                        id: apiTeam.id,
                        name: apiTeam.name,
                        code: "",
                        logo: apiTeam.logo,
                        country: apiTeam.country.name
                    )
                }

                completion(teams)
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
}

// API Response Struct
struct APIResponse: Codable {
    let response: [APIResult]
}

struct APIResult: Codable {
    let id: Int
    let name: String
    let logo: String?
    let nationnal: Bool?
    let country: APICountry
}

struct APICountry: Codable {
    let id: Int
    let name: String
    let code: String?
    let flag: String?
}

