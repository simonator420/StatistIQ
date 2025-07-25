import SwiftUI

struct Homepage: View {
    @State private var selectedTab: String = "matches"
    @State private var showLeagueSelection = false
    @State private var currentLeague = "NBA"  // default league
    
    // Placeholder for future matches
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
                // Top Bar
                Color(red: 0.12, green: 0.16, blue: 0.27)
                    .ignoresSafeArea(.all, edges: .top)
                    .frame(height: 110)
                    .overlay(
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showLeagueSelection = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Select league") // shows selected league
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
                
                // Content: Show matches from selected league
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == "matches" {
                            if let leagueMatches = matches[currentLeague], !leagueMatches.isEmpty {
                                ForEach(leagueMatches, id: \.self) { match in
                                    Button(action: { print("Tapped \(match)") }) {
                                        MatchCard() // currently always displays the same game
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
                }
                // Bottom Bar
                BottomBar(selectedTab: $selectedTab)
                    .frame(height: 40)
            }
        }
        // Overlay for league selection screen
        .overlay(
            Group {
                if showLeagueSelection {
                    ZStack {
                        // Dimmed background (tap to close)
                        Color.gray.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLeagueSelection = false
                                }
                            }
                        
                        // SelectLeagueView fades in
                        VStack {
                            Spacer()
                            SelectLeagueView(initialSelectedLeague: currentLeague, onClose: { selected in
                                currentLeague = selected
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLeagueSelection = false
                                }
                            })
                            
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                            .background(Color(red: 0.12, green: 0.16, blue: 0.27))
                            .cornerRadius(16)
                        }
                        .ignoresSafeArea(edges: .bottom)
                    }
                    .animation(.easeInOut(duration: 0.25), value: showLeagueSelection)
                }
            }
        )
        
        //        .onAppear {
        //            for family in UIFont.familyNames.sorted() {
        //                print("Family: \(family)")
        //                for name in UIFont.fontNames(forFamilyName: family) {
        //                    print("    Font: \(name)")
        //                }
        //            }
        //        }
    }
}

#Preview {
    Homepage()
}
