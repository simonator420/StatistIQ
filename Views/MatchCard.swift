import SwiftUI

struct MatchCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
                .frame(height: 230)
                .padding(.horizontal, 16)

            VStack(spacing: 8) {
                // Logos + Names
                HStack {
                    VStack(spacing: 4) {
                        Image("golden-state-warriors")
                            .resizable()
                            .frame(width: 80, height: 80)
                        Text("Warriors")
                            .font(.custom("Jost-Medium", size: 16))
                            .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    }
                    
                    Spacer()
                    
                    Text("-")
                        .font(.custom("Jost-Medium", size: 28))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    
                    Spacer()

                    VStack(spacing: 4) {
                        Image("los-angeles-lakers")
                            .resizable()
                            .frame(width: 80, height: 80)
                        Text("Lakers")
                            .font(.custom("Jost-Medium", size: 16))
                            .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                    }
                }
                .padding(.horizontal, 70) // adjusted to keep spacing balanced

                // Title
                Text("Predicted Win Probability")
                    .font(.custom("Jost-Medium", size: 16))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)

                // Win Percentages
                HStack {
                    Text("85%")
                        .font(.custom("Jost-Medium", size: 30))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))

                    Spacer()

                    Text("15%")
                        .font(.custom("Jost-Medium", size: 30))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                }
                .padding(.horizontal, 85)

                // Time and Venue
//                HStack(spacing: 4) {
//                    Text("6 p.m.")
//                        .font(.custom("Jost-Medium", size: 16))
//                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
//
//                    Text("@ Chase Center")
//                        .font(.custom("Jost-Medium", size: 16))
//                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
//                }
            }
        }
    }
}

#Preview {
    MatchCard()
}
