import SwiftUI

struct Homepage: View {
    @State private var selectedTab: String = "matches"
    @State private var showLeagueSelection = false
    @State private var currentLeague = "NBA"  // ✅ default league
    
    // ✅ Placeholder for future matches
    @State private var matches: [String: [String]] = [
        "NBA": ["Warriors vs Lakers"],
        "Euroleague": [],
        "Liga ACB": [],
        "LNB Élite": [],
        "Serie A": []
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.96)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ✅ Top Bar
                Color(red: 0.12, green: 0.16, blue: 0.27)
                    .ignoresSafeArea(.all, edges: .top)
                    .frame(height: 110)
                    .overlay(
                        Button(action: { showLeagueSelection = true }) {
                            HStack(spacing: 8) {
                                Text(currentLeague) // ✅ shows selected league
                                    .font(.custom("Jost-SemiBold", size: 24))
                                    .foregroundColor(Color(red: 0.85, green: 0.23, blue: 0.23))
                                
                                Image("chevron_down")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(Color(red: 0.85, green: 0.23, blue: 0.23))
                            }
                        }
                        .padding(.top, 50)
                        .padding(.leading, 24),
                        alignment: .topLeading
                    )
                
                // ✅ Content: Show matches from selected league
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == "matches" {
                            if let leagueMatches = matches[currentLeague], !leagueMatches.isEmpty {
                                ForEach(leagueMatches, id: \.self) { match in
                                    Button(action: { print("Tapped \(match)") }) {
                                        MatchCard() // ✅ currently always displays the same game
                                            .padding(.top, 16)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                Text("No matches available for \(currentLeague)")
                                    .font(.custom("Jost-Medium", size: 18))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            }
                        } else if selectedTab == "favorites" {
                            Text("Favorites will be here")
                                .font(.custom("Jost-Medium", size: 18))
                                .padding(.top, 40)
                        } else if selectedTab == "profile" {
                            Text("User Profile")
                                .font(.custom("Jost-Medium", size: 18))
                                .padding(.top, 40)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // ✅ Bottom Bar
                BottomBar(selectedTab: $selectedTab)
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        // ✅ Overlay for league selection screen
        .overlay(
            Group {
                if showLeagueSelection {
                    SelectLeagueView(onClose: { selected in
                        currentLeague = selected
                        showLeagueSelection = false
                        print("Selected league: \(selected)") // ✅ prepared for filtering
                    })
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showLeagueSelection)
                }
            }
        )
    }
}

#Preview {
    Homepage()
}
