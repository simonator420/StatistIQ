import SwiftUI

struct MatchCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.98, green: 0.98, blue: 0.96))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                .frame(width: 313, height: 320)

            VStack(spacing: 12) {
                // Team Logos
                HStack {
                    Image("golden-state-warriors")
                        .resizable()
                        .frame(width: 71, height: 86)

                    Spacer()

                    Image("los-angeles-lakers")
                        .resizable()
                        .frame(width: 89, height: 56)
                }
                .padding(.horizontal, 60)

                // Team Names
                HStack {
                    Text("Warriors")
                        .font(.custom("Jost-Medium", size: 16))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))

                    Spacer()

                    Text("Lakers")
                        .font(.custom("Jost-Medium", size: 16))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                }
                .padding(.horizontal, 72)

                // Title
                Text("Predicted Win Probability")
                    .font(.custom("Jost-Medium", size: 16))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)

                // Win Percentages
                HStack {
                    Text("85%")
                        .font(.custom("Jost-Medium", size: 32))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))

                    Spacer()

                    Text("15%")
                        .font(.custom("Jost-Medium", size: 32))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                }
                .padding(.horizontal, 65)

                // Time and Venue
                VStack(spacing: 4) {
                    Text("18:00")
                        .font(.custom("Jost-Medium", size: 16))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))

                    Text("@ Chase Center")
                        .font(.custom("Jost-Medium", size: 16))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                }
            }
            .padding(.vertical, 24)
        }
    }
}

#Preview {
    MatchCard()
}
