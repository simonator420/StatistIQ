import SwiftUI

struct PastGameCard: View {
    var homePrimaryColor: Color
    var awayPrimaryColor: Color
    var homeId: Int
    var awayId: Int
    var homeAbbr: String
    var awayAbbr: String
    var homeScore: String
    var awayScore: String
    var date: String
    var venue: String
    
    @EnvironmentObject var teams: TeamsDirectory
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(colorScheme == .light ? Color(.secondarySystemBackground) : Color(.systemGray6)))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                .frame(height: 100)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                // Scores + Logos
                HStack(spacing: 0) {
                    // Home team (logo + score)
                    HStack(spacing: 2) {
                        VStack(spacing:1){
                            Text(homeAbbr)
                                .font(.custom("Jost", size: 22).weight(homeWon ? .bold : .light))
                                .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                                .frame(width: 65)
                            
                            Rectangle()
                                .fill(homePrimaryColor)
                                .frame(width: 30, height: 3)
                        }
                        Text(homeScore)
                            .font(.custom("Jost", size: 22).weight(homeWon ? .bold : .light))
                            .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                            .monospacedDigit()
                            .frame(width: homeScore.count == 3 ? 65 : 55, alignment: .trailing)
                    }
                    
                    Text("–")
                        .font(.custom("Jost", size: 22).weight(.light))
                        .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                        .padding(.horizontal, 18)
                    
                    // Away team (score + logo)
                    HStack(spacing: 2) {
                        Text(awayScore)
                            .font(.custom("Jost", size: 22).weight(awayWon ? .bold : .light))
                            .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                            .monospacedDigit()
                            .frame(width: awayScore.count == 3 ? 65 : 55, alignment: .leading)
                        VStack(spacing:1){
                            Text(awayAbbr)
                                .font(.custom("Jost", size: 22).weight(awayWon ? .bold : .medium))
                                .foregroundColor(Color(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white))
                                .frame(width: 65)
                            
                            Rectangle()
                                .fill(awayPrimaryColor)
                                .frame(width: 28, height: 3)
                        }
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
    private var mainTextColor: Color {
        colorScheme == .light
        ? Color(red: 0.12, green: 0.16, blue: 0.27)
        : Color.white
    }
    
    private var homeWon: Bool {
        (Int(homeScore) ?? 0) > (Int(awayScore) ?? 0)
    }

    private var awayWon: Bool {
        (Int(awayScore) ?? 0) > (Int(homeScore) ?? 0)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Test with different score lengths
        PastGameCard(
            homePrimaryColor: Color(.red),
            awayPrimaryColor: Color(.blue),
            homeId: 145,
            awayId: 149,
            homeAbbr: "PHX",
            awayAbbr: "GSW",
            homeScore: "102",
            awayScore: "199",
            date: "21/02/2025",
            venue: "@ Chase Center"
        )
        
        PastGameCard(
            homePrimaryColor: Color(.red),
            awayPrimaryColor: Color(.blue),
            homeId: 145,
            awayId: 149,
            homeAbbr: "134",
            awayAbbr: "135",
            homeScore: "98",
            awayScore: "127",
            date: "20/02/2025",
            venue: "@ Madison Square Garden"
        )
        
        PastGameCard(
            homePrimaryColor: Color(.red),
            awayPrimaryColor: Color(.blue),
            homeId: 145,
            awayId: 149,
            homeAbbr: "141",
            awayAbbr: "145",
            homeScore: "101",
            awayScore: "92",
            date: "19/02/2025",
            venue: "@ Home Court"
        )
    }
    .padding()
    .environmentObject(TeamsDirectory.shared)
}
