import SwiftUI

struct MatchDetailView: View {
    @State private var selectedTab: String = "Summary"
    
    @State private var isHomeFavorite: Bool = false
    @State private var isAwayFavorite: Bool = false
    
    @State private var showInfoSheet = false
    @State private var infoText: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    let logosSize: Int = 60
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section (Full Width)
            ZStack(alignment: .topLeading) {
                Color(red: 0.12, green: 0.16, blue: 0.27)
                    .ignoresSafeArea(.all, edges: .top)
                
                VStack(spacing: 8) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .medium))
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                    }
                    .padding(.top, 30)
                    
                    // Centered match info
                    VStack(spacing: 4) {
                        Text("18:00")
                        Text("Today")
                        Text("@ San Francisco, USA")
                    }
                    .font(.custom("Jost", size: 16).weight(.medium))
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, -30)
                    .padding(.bottom, 20)
                    
                    // Teams and Logos
                    HStack {
                        // Left team
                        VStack(spacing: 2) {
                            Image("golden-state-warriors")
                                .resizable()
                                .frame(width: 90, height: 90)
                            Text("Warriors")
                                .font(.custom("Jost-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.top, 5.0)
                            // TODO: Load it only once when initializing the page
                            RecentGamesView(results: (0..<5).map { _ in Bool.random() })
                        }
                        .multilineTextAlignment(.center)
                        
                        // Stars centered
                        HStack(spacing: 80) {
                            Button(action: { isHomeFavorite.toggle() }) {
                                Image(systemName: isHomeFavorite ? "star.fill" : "star")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            }
                            Button(action: { isAwayFavorite.toggle() }) {
                                Image(systemName: isAwayFavorite ? "star.fill" : "star")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.bottom, 45.0)
                        .frame(maxWidth: .infinity)
                        
                        // Right team
                        VStack(spacing: 2) {
                            Image("los-angeles-lakers")
                                .resizable()
                                .frame(width: 90, height: 90)
                            Text("Lakers")
                                .font(.custom("Jost-SemiBold", size: 16))
                                .foregroundColor(.white)
                                .padding(.top, 5.0)
                            RecentGamesView(results: (0..<5).map { _ in Bool.random() })
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                    
                    HStack(spacing: 0) {
                        ForEach(["Summary", "Games"], id: \.self) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                VStack(spacing: 4) {
                                    Text(tab)
                                        .font(.custom("Jost-SemiBold", size: 16))
                                        .foregroundColor(selectedTab == tab ? .white : .gray)
                                    // White if selected, blue if not
                                    Rectangle()
                                        .fill(selectedTab == tab ? Color.white : Color(red: 0.12, green: 0.16, blue: 0.27))
                                        .frame(height: 6)
                                        
                                }
                                .frame(maxWidth: .infinity)
                                
                            }
                        }
                    }
//                    .padding(.top, 14)
                    .zIndex(2)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 337.3)
            
            // Scrollable content below top bar
            ScrollView {
                VStack(spacing: 28) {
                    if selectedTab == "Summary" {
                        Group {
                            // Win Probability
                            VStack(spacing: 5) {
                                HStack(spacing: 4) {
                                    Text("Win Probability")
                                        .font(.custom("Jost", size: 16).weight(.medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        infoText = """
                                        Win Probability represents the chance each team has to win the game, based on factors like recent form, player performance, injuries, and historical matchups.
                                        
                                        It's calculated using AI models trained on real game data and updated for every matchup.
                                        
                                        A higher percentage means the team is more likely to win — but upsets are always possible.
                                        """
                                        showInfoSheet = true
                                        
                                    }) {
                                        Image(systemName: "info.circle")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.top, 25.0)
                                
                                HStack(spacing: 120) {
                                    Text("85%")
                                    Text("15%")
                                }
                                .font(.custom("Jost", size: 32).weight(.medium))
                                .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                            }
                            
                            // Predicted Points Range
                            VStack(spacing: 10) {
                                HStack(spacing: 4) {
                                    Text("Predicted Points Range")
                                        .font(.custom("Jost", size: 16).weight(.medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        infoText = """
                                        Predicted Points Range shows the expected scoring interval for each team based on statistical models.
                                        
                                        These predictions take into account factors such as offensive and defensive efficiency, pace of play, player availability, and historical matchups.
                                        
                                        The actual score may vary, but this range provides an estimate of where the final points are most likely to fall.
                                        """
                                        
                                        showInfoSheet = true
                                        
                                    }) {
                                        Image(systemName: "info.circle")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                HStack(spacing: 70) {
                                    Text("102 - 108")
                                    Text("92 - 98")
                                }
                                .font(.custom("Jost", size: 32).weight(.medium))
                                .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                            }
                            
                            // Expected Margin
                            VStack(spacing: 10) {
                                HStack(spacing: 4) {
                                    Text("Expected Margin of Victory")
                                        .font(.custom("Jost", size: 16).weight(.medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        infoText = """
                                        Expected Margin of Victory indicates how many points a team is predicted to win by, on average, according to the model.
                                        
                                        It is calculated using factors like team strength, recent performance, player matchups, and game location.
                                        
                                        A positive margin favors the listed team, while a negative margin would favor their opponent. The larger the margin, the more dominant the expected performance.
                                        """
                                        
                                        showInfoSheet = true
                                        
                                    }) {
                                        Image(systemName: "info.circle")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Text("+11.3 Warriors")
                                    .font(.custom("Jost", size: 32).weight(.medium))
                                    .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                            }
                            
                            // Key Players
                            VStack(spacing: 10) {
                                HStack(spacing: 4) {
                                    Text("Predicted Stats For Key Players")
                                        .font(.custom("Jost", size: 16).weight(.medium))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        infoText = """
                                        Predicted Stats for Key Players provide an estimate of how the top performers on each team are likely to play in the upcoming game.
                                        
                                        These predictions are based on player trends, opponent defensive matchups, recent form, and historical performance in similar situations.
                                        
                                        While these stats offer insights into potential impact players, actual results can vary depending on in-game factors.
                                        """
                                        
                                        showInfoSheet = true
                                        
                                    }) {
                                        Image(systemName: "info.circle")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                HStack(spacing: 90) {
                                    VStack(spacing: 8) {
                                        Image("curry")
                                            .resizable()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                        Text("S. Curry")
                                            .font(.custom("Jost", size: 22))
                                            .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                        VStack(spacing: 2) {
                                            Text("28.2 PTS")
                                            Text("2.8 REB")
                                            Text("6.4 AST")
                                        }
                                        .font(.custom("Jost-Medium", size: 22))
                                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Image("james")
                                            .resizable()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                        Text("L. James")
                                            .font(.custom("Jost", size: 22).weight(.medium))
                                            .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                        VStack(spacing: 2) {
                                            Text("23.1 PTS")
                                            Text("6.3 REB")
                                            Text("2.1 AST")
                                        }
                                        .font(.custom("Jost", size: 22).weight(.medium))
                                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    } else if selectedTab == "Games" {
                        // Placeholder for recent games
                        VStack(spacing: 16) {
                            PastGameCard(
                                homeLogo: "golden-state-warriors",
                                awayLogo: "los-angeles-lakers",
                                homeScore: "102",
                                awayScore: "99",
                                date: "21/02/2025",
                                venue: "@ Chase Center"
                            )
                            
                            PastGameCard(
                                homeLogo: "los-angeles-lakers",
                                awayLogo: "golden-state-warriors",
                                homeScore: "110",
                                awayScore: "105",
                                date: "18/02/2025",
                                venue: "@ Crypto.com Arena"
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 25.0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            // Disable scrolling over the the Summary and Games tab
//            .padding(.top, 3)
        }
        .overlay(
            Group {
                if showInfoSheet {
                    InfoSheet(infoText: infoText, onDismiss: {
                        showInfoSheet = false
                    })
                    .zIndex(2)
                }
            }
        )
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
}

#Preview {
    MatchDetailView()
}
