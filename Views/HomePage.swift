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
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar
                    Color(red: 0.12, green: 0.16, blue: 0.27)
                        .ignoresSafeArea(.all, edges: .top)
                        .frame(height: 70)
                        .overlay(
                            Group {
                                if selectedTab == "matches" {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            showLeagueSelection = true
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Text("Select league")
                                                .font(.custom("Jost-SemiBold", size: 22))
                                                .foregroundColor(Color.white)
                                            
                                            Image("chevron_down_white")
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        }
                                    }
                                    
                                }
                                else if selectedTab == "favorites" {
                                    Text("Favorites")
                                        .font(.custom("Jost-SemiBold", size: 22))
                                        .foregroundColor(Color.white)
                                }
                            }
                                .padding(.top, 25)
                                .padding(.leading, 24),
                            alignment: .topLeading
                        )
                    
                    
                    // Content: Show matches from selected league
                    ScrollView {
                        VStack(spacing: 16) {
                            if selectedTab == "matches" {
                                if let leagueMatches = matches[currentLeague], !leagueMatches.isEmpty {
                                    ForEach(leagueMatches, id: \.self) { match in
                                        NavigationLink(destination: MatchDetailView()) {
                                            MatchCard()
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
                            VStack {
                                Spacer()
                                SelectLeagueView(initialSelectedLeague: currentLeague ,onClose: { selected in
                                    currentLeague = selected
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showLeagueSelection = false
                                    }
                                })
                                
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
                                .cornerRadius(16)
                            }
                            .ignoresSafeArea(edges: .bottom)
                        }
                        .transition(AnyTransition.move(edge: .bottom))
                        .zIndex(2)
                        
                        Color.gray.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showLeagueSelection = false
                                }
                            }
                            .zIndex(0)
                    }
                }
            )
        }
    }
}

#Preview {
    Homepage()
}
