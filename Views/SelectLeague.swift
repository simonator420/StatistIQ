import SwiftUI

struct League: Identifiable {
    let id = UUID()
    let name: String
    let logo: String
    let flag: String
}

struct SelectLeagueView: View {
    @State private var selectedLeague: String = "NBA" // ✅ Default selected league
    
    /// Callback sends selected league back to Homepage
    var onClose: (_ selected: String) -> Void

    // Example leagues
    let leagues: [League] = [
        League(name: "NBA", logo: "nba_logo", flag: "usa_flag"),
        League(name: "Euroleague", logo: "euroleague_logo", flag: "europe_flag"),
        League(name: "Liga ACB", logo: "acb_logo", flag: "spain_flag"),
        League(name: "LNB Élite", logo: "lnb_logo", flag: "france_flag"),
        League(name: "Serie A", logo: "seriea_logo", flag: "italy_flag")
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // ✅ Background dark blue
            Color(red: 0.12, green: 0.16, blue: 0.27)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // ✅ Header with close button
                HStack {
                    Button(action: { onClose(selectedLeague) }) {
                        Image("X")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    Spacer()
                    Text("Select league")
                        .font(.custom("Jost-SemiBold", size: 24))
                        .foregroundColor(Color(red: 0.85, green: 0.23, blue: 0.23))
                    Spacer()
                }
                .padding(.top, 50) // ✅ same Y as homepage
                .padding(.horizontal, 24)

                // ✅ League List
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(leagues) { league in
                        Button(action: {
                            selectedLeague = league.name
                            onClose(league.name) // ✅ send selected league & close
                        }) {
                            HStack(spacing: 12) {
                                Image(league.logo)
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                
                                Text(league.name)
                                    .font(.custom("Jost-SemiBold", size: 16))
                                    .foregroundColor(
                                        selectedLeague == league.name ?
                                        Color(red: 0.85, green: 0.23, blue: 0.23) : // ✅ highlight red
                                        Color.white
                                    )
                                
                                Spacer()
                                
                                Image(league.flag)
                                    .resizable()
                                    .frame(width: 26, height: 18)
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                            .padding(.leading, 35)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    SelectLeagueView(onClose: { selected in print("Selected: \(selected)") })
}
