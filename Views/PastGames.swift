import SwiftUICore
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
                .fill(Color(red: 0.98, green: 0.98, blue: 0.96))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                .frame(width: 313, height: 160)
            
            VStack(spacing: 8) {
                // Scores + Logos
                HStack(spacing: 12) {
                    Image(homeLogo)
                        .resizable()
                        .frame(width: 54, height: 65)
                    
                    Text(homeScore)
                        .font(.custom("Jost", size: 24).weight(.medium))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    
                    Text("-")
                        .font(.custom("Jost", size: 24).weight(.medium))
                        .foregroundColor(.black)
                    
                    Text(awayScore)
                        .font(.custom("Jost", size: 24).weight(.medium))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    
                    Image(awayLogo)
                        .resizable()
                        .frame(width: 65, height: 40)
                }
                
                // Date + Venue
                VStack(spacing: 4) {
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
