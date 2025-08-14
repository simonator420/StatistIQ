import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentScrollView: View {
    @ObservedObject var net: NetworkMonitor
    @Binding var selectedTab: String
    @Binding var isLoggedIn: Bool
    @Binding var hasFavoriteMatches: Bool
    @Binding var currentLeague: String
    @Binding var currentUser: [String: Any]
    
    // keep visuals identical by passing your helpers
    let signInButton: () -> AnyView
    let adBanner: () -> AnyView
    let fetchUserProfile: (String, @escaping ([String: Any]?) -> Void) -> Void
    @ObservedObject var scheduleStore: GamesScheduleStore
    @ObservedObject private var teamsDir = TeamsDirectory.shared
    @StateObject private var favoritesStore = FavoritesStore()
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    if !net.isConnected {
                        VStack(spacing:20){
                            Image(systemName: "wifi.slash")
                                .resizable()
                                .frame(width: 48, height: 48)
                                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                .padding(.top, 20)
                            
                            Text("Please check your connection to load matches and favorites.")
                                .font(.custom("Jost", size: 16).weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                .frame(width: 270, alignment: .center)
                        }
                        .padding(.top, 119)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    } else {
                        
                        if selectedTab == "matches" {
                            if !teamsDir.isLoaded {
                                EmptyView()
                            } else if !scheduleStore.gameIds.isEmpty {
                                // Filter by league
                                let wantNBA = (currentLeague == "NBA")
                                
                                let filteredIds = scheduleStore.gameIds.filter { gid in
                                    guard let meta = scheduleStore.gameMeta[gid],
                                          let home = teamsDir.team(meta.homeId),
                                          let away = teamsDir.team(meta.awayId) else {
                                        return false
                                    }
                                    let homeNBA = (home.nba_team == true)
                                    let awayNBA = (away.nba_team == true)
                                    // Show games only if BOTH teams match the selected league
                                    return wantNBA ? (homeNBA && awayNBA) : (!homeNBA && !awayNBA)
                                }
                                
                                if filteredIds.isEmpty {
                                    VStack(spacing: 16) {
                                        adBanner().padding(.top, 16)
                                        Text("No matches available for \(currentLeague)")
                                            .font(.custom("Jost-Medium", size: 18))
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                    }
                                } else {
                                    ForEach(Array(filteredIds.enumerated()), id: \.element) { index, gameId in
                                        VStack(spacing: 0) {
                                            NavigationLink {
                                                MatchDetailView(gameId: gameId)
                                                    .toolbar(.hidden, for: .navigationBar)
                                                    .navigationBarBackButtonHidden(true)
                                            } label: {
                                                MatchCard(gameId: gameId)
                                                    .padding(.top, 16)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            if index == 0 {
                                                adBanner()
                                                    .padding(.top, 16)
                                            }
                                        }
                                    }
                                }
                            } else {
                                if scheduleStore.isLoading {
                                    EmptyView() // spinner is on top
                                } else {
                                    VStack(spacing: 16) {
                                        adBanner().padding(.top, 16)
                                        Text("No matches available for \(currentLeague)")
                                            .font(.custom("Jost-Medium", size: 18))
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                    }
                                }
                            }
                        } else if selectedTab == "favorites" {
                            if !isLoggedIn {
                                // unchanged sign-in UI...
                                VStack(spacing: 20) {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                        .padding(.top, 20)
                                    
                                    Text("Sign in to view the matches of your favorite teams.")
                                        .font(.custom("Jost", size: 16).weight(.medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                        .frame(width: 270, alignment: .center)
                                    
                                    NavigationLink(destination: SignInView(onLogin: {
                                        isLoggedIn = true
                                        if let uid = Auth.auth().currentUser?.uid {
                                            fetchUserProfile(uid) { data in
                                                if let data = data { self.currentUser = data }
                                            }
                                        }
                                    })) { signInButton() }
                                        .padding(.top, 10)
                                }
                                .padding(.top, 119)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            } else {
                                // 1) favorite team IDs from user doc
                                let favoriteTeamIds = favoritesStore.favorites
                                
                                // 2) upcoming games where either side is a favorite
                                let favoriteGameIds: [Int] = scheduleStore.gameIds.filter { gid in
                                    guard let meta = scheduleStore.gameMeta[gid] else { return false }
                                    return favoriteTeamIds.contains(meta.homeId) || favoriteTeamIds.contains(meta.awayId)
                                }
                                
                                if favoriteGameIds.isEmpty {
                                    VStack(spacing: 20) {
                                        Image(systemName: "calendar")
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .padding(.top, 40)
                                        
                                        Text("No upcoming matches for your favorite teams yet.")
                                            .font(.custom("Jost", size: 16).weight(.medium))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .frame(width: 296, alignment: .center)
                                    }
                                    .padding(.top, 160)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    ForEach(Array(favoriteGameIds.enumerated()), id: \.element) { index, gameId in
                                        VStack(spacing: 0) {
                                            NavigationLink {
                                                MatchDetailView(gameId: gameId)
                                                    .toolbar(.hidden, for: .navigationBar)
                                                    .navigationBarBackButtonHidden(true)
                                            } label: {
                                                MatchCard(gameId: gameId)
                                                    .padding(.top, 16)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            if index == 0 {
                                                adBanner()
                                                    .padding(.top, 16)
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } else if selectedTab == "profile" {
                            if !isLoggedIn {
                                VStack(spacing: 20) {
                                    Text("Sign in for the best user experience!")
                                        .font(.custom("Jost", size: 16).weight(.medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                        .frame(width: 270, alignment: .center)
                                    
                                    NavigationLink(destination: SignInView(onLogin: {
                                        isLoggedIn = true
                                        if let uid = Auth.auth().currentUser?.uid {
                                            fetchUserProfile(uid) { data in
                                                if let data = data {
                                                    self.currentUser = data
                                                }
                                            }
                                        }
                                    })) {
                                        signInButton()
                                    }
                                    .padding(.top, 10)
                                    
                                }
                                .padding(.top, 60)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                Button("Log out") {
                                    try? Auth.auth().signOut()
                                    UserDefaults.standard.set(false, forKey: "isLoggedIn")
                                    isLoggedIn = false
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await refresh()
            }
            
            
            if selectedTab == "matches",
               net.isConnected,
               (scheduleStore.isLoading || !teamsDir.isLoaded) {
                
                Color.black.opacity(0.05).ignoresSafeArea().zIndex(1)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                    .scaleEffect(1.4)
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .transition(.opacity)
                    .zIndex(2)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            if isLoggedIn { favoritesStore.start() }    // <- start on first show
        }
        .onChange(of: isLoggedIn) { loggedIn in         // <- keep in sync with auth
            if loggedIn { favoritesStore.start() } else { favoritesStore.stop() }
        }
    }
    
    private func asInt(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        return nil
    }
    
    @MainActor
    private func refresh() async {
        // Matches: restart the listener (keeps your same query)
        if selectedTab == "matches" {
            scheduleStore.start()
        }
        // Favorites: restart the live listener (and optionally re-fetch profile if you still use it elsewhere)
        else if selectedTab == "favorites" {
            if isLoggedIn {
                favoritesStore.start()
                // If you still rely on currentUser somewhere:
                if let uid = Auth.auth().currentUser?.uid {
                    await withCheckedContinuation { cont in
                        fetchUserProfile(uid) { data in
                            if let data = data { self.currentUser = data }
                            cont.resume()
                        }
                    }
                }
            }
        }
        // Tiny delay is optional—just to keep the spinner visible briefly.
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}

