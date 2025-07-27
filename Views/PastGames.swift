import SwiftUI

struct PastGameCard: View {
    var homeLogo: String
    var awayLogo: String
    var homeScore: String
    var awayScore: String
    var date: String
    var venue: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                .frame(width: 313, height: 160)
            
            VStack(spacing: 8) {
                // Scores + Logos
                HStack(spacing: 15) {
                    Image(homeLogo)
                        .resizable()
                        .frame(width: 55, height: 55)
                    
                    Text(homeScore)
                        .font(.custom("Jost", size: 32).weight(.medium))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    
                    Text("-")
                        .font(.custom("Jost", size: 32).weight(.medium))
                        .foregroundColor(.black)
                    
                    Text(awayScore)
                        .font(.custom("Jost", size: 32).weight(.medium))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    
                    Image(awayLogo)
                        .resizable()
                        .frame(width: 55, height: 55)
                }
                
                // Date + Venue
                VStack(spacing: 6) {
                    Text(date)
                        .font(.custom("Jost", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    
                    Text(venue)
                        .font(.custom("Jost", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                }
            }
        }
    }
}


#Preview {
    PastGameCard(
        homeLogo: "golden-state-warriors",
        awayLogo: "los-angeles-lakers",
        homeScore: "102",
        awayScore: "99",
        date: "21/02/2025",
        venue: "@ Chase Center"
    )
}
