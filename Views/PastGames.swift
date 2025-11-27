import SwiftUI

struct PastGameCard: View {
    var homeLogo: String
    var awayLogo: String
    var homeScore: String
    var awayScore: String
    var date: String
    var venue: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorScheme == .light ? Color.white : Color(.systemGray6)))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                .frame(height: 115)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                // Scores + Logos
                HStack(spacing: 0) {
                    // Home team (logo + score)
                    HStack(spacing: 2) {
                        Image(homeLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .padding(.leading, homeScore.count == 3 ? 0 : 20)
                        
                        Text(homeScore)
                            .font(.custom("Jost", size: 28).weight(.medium))
                            .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                            .monospacedDigit()
                            .frame(width: homeScore.count == 3 ? 75 : 55, alignment: .trailing)
                    }
                    
                    Text("–")
                        .font(.custom("Jost", size: 28).weight(.medium))
                        .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                        .padding(.horizontal, 15)
                    
                    // Away team (score + logo)
                    HStack(spacing: 2) {
                        Text(awayScore)
                            .font(.custom("Jost", size: 28).weight(.medium))
                            .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                            .monospacedDigit()
                            .frame(width: awayScore.count == 3 ? 75 : 55, alignment: .leading)
                        
                        Image(awayLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .padding(.trailing, awayScore.count == 3 ? 0 : 20)
                    }
                }
                
                // Date + Venue
                VStack(spacing: 6) {
                    Text(date)
                        .font(.custom("Jost", size: 16).weight(.medium))
                        .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                    
//                    Text(venue)
//                        .font(.custom("Jost", size: 16).weight(.medium))
//                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Test with different score lengths
        PastGameCard(
            homeLogo: "134",
            awayLogo: "135",
            homeScore: "102",
            awayScore: "199",
            date: "21/02/2025",
            venue: "@ Chase Center"
        )
        
        PastGameCard(
            homeLogo: "134",
            awayLogo: "135",
            homeScore: "98",
            awayScore: "127",
            date: "20/02/2025",
            venue: "@ Madison Square Garden"
        )
        
        PastGameCard(
            homeLogo: "141",
            awayLogo: "145",
            homeScore: "101",
            awayScore: "92",
            date: "19/02/2025",
            venue: "@ Home Court"
        )
    }
    .padding()
}
