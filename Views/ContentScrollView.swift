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
    @Environment(\.colorScheme) private var colorScheme
    
    // keep visuals identical by passing helpers
    let signInButton: () -> AnyView
    //    let adBanner: () -> AnyView
    let fetchUserProfile: (String, @escaping ([String: Any]?) -> Void) -> Void
    @ObservedObject var scheduleStore: GamesScheduleStore
    @ObservedObject private var teamsDir = TeamsDirectory.shared
    @StateObject private var favoritesStore = FavoritesStore()
    @State private var isFavoritesExpanded: Bool = false
    
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
                                
                                // TODO Soon text for Euroleague
                                
                                if filteredIds.isEmpty {
                                    Text("No matches available for \(currentLeague)")
                                        .font(.custom("Jost-Medium", size: 18))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                        .onAppear {
                                            print("This is current league: \(currentLeague) ")
                                        }
                                } else {
                                    
                                    let calendar  = Calendar.current
                                    let gameStart = self.scheduleStore.gameStart            // [Int: Date]
                                    let gameMeta  = self.scheduleStore.gameMeta             // [Int: (homeId: Int, awayId: Int)]
                                    let now       = Date()
                                    
                                    // Build (id, start, home, away) only for games that have a start time
                                    // and are not later than 2.5 hours after kickoff
                                    let games: [(id: Int, start: Date, home: Int, away: Int)] =
                                        filteredIds.compactMap { gid -> (id: Int, start: Date, home: Int, away: Int)? in
                                            guard let dt = gameStart[gid], let meta = gameMeta[gid] else { return nil }
                                            // Keep if now <= start + 2.5h  (2.5h = 9000s)
                                            guard now <= dt.addingTimeInterval(9_000) else { return nil }
                                            return (id: gid, start: dt, home: meta.homeId, away: meta.awayId)
                                        }
                                        .sorted { $0.start < $1.start } // earliest first
                                    
                                    if !games.isEmpty {
                                        // Greedy cover: keep a game iff it introduces any yet-unseen team
                                        let pickedAgg = games.reduce(into: (covered: Set<Int>(), items: [(id: Int, start: Date)]())) { acc, g in
                                            if !acc.covered.contains(g.home) || !acc.covered.contains(g.away) {
                                                acc.items.append((id: g.id, start: g.start))
                                                acc.covered.insert(g.home)
                                                acc.covered.insert(g.away)
                                            }
                                        }
                                        let pickedGames = pickedAgg.items  // [(id, start)] one match per team overall (earliest)
                                        
                                        // Group the selected games by local calendar day
                                        let grouped = Dictionary(grouping: pickedGames) { item -> Date in
                                            calendar.startOfDay(for: item.start)
                                        }
                                        let sortedDays = grouped.keys.sorted()
                                        
                                        ForEach(sortedDays, id: \.self) { day in
                                            if let dayGames = grouped[day] {
                                                // Date header
                                                let headerText = day.formatted(.dateTime.weekday(.wide).day().month().year())
                                                Text(headerText)
                                                    .font(.custom("Jost", size: 16).weight(.medium))
                                                    .foregroundColor(.secondary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.top, 8)
                                                    .padding(.horizontal)
                                                
                                                // Matches for that date (already earliest order globally; sort again within the day)
                                                ForEach(dayGames.sorted(by: { $0.start < $1.start }), id: \.id) { item in
                                                    NavigationLink {
                                                        MatchDetailView(gameId: item.id)
                                                            .toolbar(.hidden, for: .navigationBar)
                                                            .navigationBarBackButtonHidden(true)
                                                    } label: {
                                                        MatchCard(gameId: item.id)
                                                            
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                        }
                                        
                                    } else {
                                        // Fallback: if no start times present, show the usual list
                                        ForEach(Array(filteredIds.enumerated()), id: \.element) { _, gameId in
                                            NavigationLink {
                                                MatchDetailView(gameId: gameId)
                                                    .toolbar(.hidden, for: .navigationBar)
                                                    .navigationBarBackButtonHidden(true)
                                            } label: {
                                                MatchCard(gameId: gameId)
                                                    
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            } else {
                                if scheduleStore.isLoading {
                                    EmptyView() // spinner is on top
                                } else {
                                    Text("No matches available for \(currentLeague)")
                                        .font(.custom("Jost-Medium", size: 18))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                }
                            }
                        } else if selectedTab == "favorites" {
                            if !isLoggedIn {
                                VStack(spacing: 20) {
//                                    Image(systemName: "person.crop.circle")
//                                        .resizable()
//                                        .frame(width: 48, height: 48)
//                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
//                                        .padding(.top, 20)
                                    
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 46, height: 46)
                                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                        .padding(.top, 8)

                                    
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
                                    // Same style as “matches”: earliest, one game per team, date separators, 2.5h cutoff
                                    let calendar  = Calendar.current
                                    let now       = Date()
                                    let gameStart = self.scheduleStore.gameStart      // [Int: Date]
                                    let gameMeta  = self.scheduleStore.gameMeta       // [Int: (homeId: Int, awayId: Int)]

                                    // Build candidates only from favoriteGameIds, keep only games not later than 2.5h after start
                                    // Tuple: (id, start, home, away)
                                    let candidates: [(id: Int, start: Date, home: Int, away: Int)] =
                                        favoriteGameIds.compactMap { gid -> (id: Int, start: Date, home: Int, away: Int)? in
                                            guard let dt = gameStart[gid], let meta = gameMeta[gid] else { return nil }
                                            guard now <= dt.addingTimeInterval(9_000) else { return nil } // 2.5h = 9000s
                                            return (id: gid, start: dt, home: meta.homeId, away: meta.awayId)
                                        }
                                        .sorted { $0.start < $1.start } // earliest first

                                    if candidates.isEmpty {
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
                                        // We want one game per favorite team (not per all teams in the list)
                                        // Limit the coverage set to favorites that actually appear in candidates
                                        let favoritesPresent: Set<Int> = Set(candidates.flatMap { [$0.home, $0.away] }).intersection(favoritesStore.favorites)

                                        // Greedy earliest cover: pick a game iff it covers any uncovered favorite team
                                        let pickedAgg = candidates.reduce(into: (covered: Set<Int>(), items: [(id: Int, start: Date)]())) { acc, g in
                                            let introducesHomeFav = favoritesPresent.contains(g.home) && !acc.covered.contains(g.home)
                                            let introducesAwayFav = favoritesPresent.contains(g.away) && !acc.covered.contains(g.away)
                                            if introducesHomeFav || introducesAwayFav {
                                                acc.items.append((id: g.id, start: g.start))
                                                if favoritesPresent.contains(g.home) { acc.covered.insert(g.home) }
                                                if favoritesPresent.contains(g.away) { acc.covered.insert(g.away) }
                                            }
                                        }
                                        let picked = pickedAgg.items  // [(id, start)] one per favorite team (earliest possible)

                                        if picked.isEmpty {
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
                                            // Group by local calendar day and render with date separators
                                            let grouped = Dictionary(grouping: picked) { item -> Date in
                                                calendar.startOfDay(for: item.start)
                                            }
                                            let sortedDays = grouped.keys.sorted()

                                            ForEach(sortedDays, id: \.self) { day in
                                                if let dayGames = grouped[day] {
                                                    let headerText = day.formatted(.dateTime.weekday(.wide).day().month().year())
                                                    Text(headerText)
                                                        .font(.custom("Jost", size: 16))
                                                        .foregroundColor(.secondary)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                        .padding(.top, 8)
                                                        .padding(.horizontal)

                                                    ForEach(dayGames.sorted(by: { $0.start < $1.start }), id: \.id) { item in
                                                        NavigationLink {
                                                            MatchDetailView(gameId: item.id)
                                                                .toolbar(.hidden, for: .navigationBar)
                                                                .navigationBarBackButtonHidden(true)
                                                        } label: {
                                                            MatchCard(gameId: item.id)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } else if selectedTab == "profile" {
                             if !isLoggedIn {
                                 
                                 Spacer(minLength: 0)
                                 
                                 VStack(spacing:20) {
                                     
                                     // BENEFITS (no alerts)
                                     VStack(spacing: 12) {
                                         HStack(alignment: .center, spacing: 10) {
                                             Image(systemName: "star.fill")
                                                 .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                                 .frame(width: 22)
                                             VStack(alignment: .leading, spacing: 2) {
                                                 Text("Favorites feed")
                                                     .font(.custom("Jost", size: 15).weight(.semibold))
                                                 Text("All your teams in one place.")
                                                     .font(.custom("Jost", size: 13))
                                                     .foregroundColor(.secondary)
                                             }
                                             Spacer()
                                         }
                                         .padding(12)
                                         .background(Color(.systemGray6))
                                         .cornerRadius(12)
                                         
                                         HStack(alignment: .center, spacing: 10) {
                                             Image(systemName: "chart.bar.fill")
                                                 .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                                 .frame(width: 22)
                                             VStack(alignment: .leading, spacing: 2) {
                                                 Text("AI predictions")
                                                     .font(.custom("Jost", size: 15).weight(.semibold))
                                                 Text("Win probabilities and expected margins.")
                                                     .font(.custom("Jost", size: 13))
                                                     .foregroundColor(.secondary)
                                             }
                                             Spacer()
                                         }
                                         .padding(12)
                                         .background(Color(.systemGray6))
                                         .cornerRadius(12)
                                     }
                                     .padding(.horizontal)
                                     
                                     // PRIMARY CTA
                                     NavigationLink(destination: SignInView(onLogin: {
                                         isLoggedIn = true
                                         if let uid = Auth.auth().currentUser?.uid {
                                             fetchUserProfile(uid) { data in
                                                 if let data = data { self.currentUser = data }
                                             }
                                         }
                                     })) {
                                         HStack(spacing: 10) {
                                             Image(systemName: "person.fill.badge.plus")
                                             Text("Sign in to StatistIQ")
                                                 .font(.custom("Jost", size: 16).weight(.semibold))
                                         }
                                         .foregroundColor(.white)
                                         .frame(maxWidth: .infinity)
                                         .padding(.vertical, 12)
                                         .background(Color(red: 0.12, green: 0.16, blue: 0.27))
                                         .cornerRadius(12)
                                         .padding(.horizontal)
                                     }
                                     .buttonStyle(.plain)
                                     
                                     // SECONDARY CTA — browse matches first
//                                     Button {
//                                         selectedTab = "matches"
//                                     } label: {
//                                         HStack(spacing: 8) {
//                                             Image(systemName: "sportscourt.fill")
//                                             Text("Browse today’s matches")
//                                                 .font(.custom("Jost", size: 15).weight(.medium))
//                                         }
//                                         .foregroundColor(.primary)
//                                         .padding(.horizontal, 14)
//                                         .padding(.vertical, 10)
//                                         .background(Color.secondary.opacity(0.12))
//                                         .clipShape(Capsule())
//                                     }
//                                     
                                     // Trust line
                                     HStack(spacing: 6) {
                                         Image(systemName: "lock.fill")
                                             .font(.system(size: 12, weight: .semibold))
                                             .foregroundColor(.secondary)
                                         Text("We use your data only to personalize your feed.")
                                             .font(.custom("Jost", size: 12))
                                             .foregroundColor(.secondary)
                                     }
                                     .padding(.top, 2)
                                     
                                     // Optional preview spacing
                                     Spacer(minLength: 0)
                                 }
                                
//                                VStack(spacing: 20) {
//                                    Text("Sign in for the best user experience!")
//                                        .font(.custom("Jost", size: 16).weight(.medium))
//                                        .multilineTextAlignment(.center)
//                                        .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
//                                        .frame(width: 270, alignment: .center)
//                                    
//                                    NavigationLink(destination: SignInView(onLogin: {
//                                        isLoggedIn = true
//                                        if let uid = Auth.auth().currentUser?.uid {
//                                            fetchUserProfile(uid) { data in
//                                                if let data = data {
//                                                    self.currentUser = data
//                                                }
//                                            }
//                                        }
//                                    })) {
//                                        signInButton()
//                                    }
//                                    .padding(.top, 10)
//                                    
//                                }
//                                .padding(.top, 60)
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                 
                                 
                                 
                                 
                                 
                                 
                            } else {
                                VStack(spacing: 16) {
                                    //                                    Button("Log out") {
                                    //                                        try? Auth.auth().signOut()
                                    //                                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                                    //                                        isLoggedIn = false
                                    //                                    }
                                    Spacer()
                                    
                                    HStack {
                                        Text("Manage favorites")
                                            .font(.custom("Jost", size: 16).weight(.medium))
                                            .foregroundColor(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .rotationEffect(.degrees(isFavoritesExpanded ? 90 : 0)) // rotates right -> down
                                            .foregroundColor(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white)
                                            .font(.system(size: 16, weight: .semibold))
                                        //  .contentTransition(.symbolEffect)
                                            .animation(.easeInOut(duration: 0.2), value: isFavoritesExpanded)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isFavoritesExpanded.toggle()
                                        }
                                    }
                                    
                                    if isFavoritesExpanded {
                                        VStack(alignment: .leading, spacing: 12) {
                                            let favs = favoritesStore.favorites
                                            
                                            if favs.isEmpty {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Browse matches and add a team to your favorites to start tracking their games.")
                                                        .font(.custom("Jost", size: 14))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Button {
                                                        // Navigate user to the Matches tab so they can pick favorites
                                                        selectedTab = "matches"
                                                    } label: {
                                                        HStack(spacing: 8) {
                                                            Image(systemName: "star.fill")
                                                            Text("Browse matches")
                                                        }
                                                        .font(.custom("Jost", size: 14).weight(.medium))
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(Color(.systemGray5))
                                                        .clipShape(Capsule())
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            } else {
                                                Text("Your favorite teams")
                                                    .font(.custom("Jost", size: 14).weight(.semibold))
                                                    .foregroundColor(Color.primary)
                                                
                                                ForEach(Array(favs), id: \.self) { tid in
                                                    HStack(spacing: 10) {
                                                        teamLogo(for: tid)
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 24, height: 24)
                                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                                        
                                                        Text(teamName(for: tid))
                                                            .font(.custom("Jost", size: 14))
                                                            .foregroundColor(.primary)
                                                        
                                                        Spacer()
                                                        
                                                        Button {
                                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                                favoritesStore.toggle(teamId: tid)   // removes from favorites
                                                            }
                                                        } label: {
                                                            Image(systemName: "star.fill")
                                                                .font(.system(size: 16, weight: .semibold))
                                                                .foregroundColor(.yellow)
                                                                .accessibilityLabel("Remove from favorites")
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                    .padding(.vertical, 6)
                                                    .padding(.horizontal, 8)
                                                    .background(Color(.systemGray6))
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Share with friends")
                                                .font(.custom("Jost", size: 18).weight(.semibold))
                                                .foregroundColor(.white)
                                            
                                            Text("Enjoying StatistiQ? Let others know and share the app!")
                                                .font(.custom("Jost", size: 14))
                                                .foregroundColor(.white)
                                                .padding(.bottom, 7)
                                            
                                            
                                            ShareLink(item: URL(string: "https://apple.com")! ){
                                                Label("Share link", systemImage: "square.and.arrow.up")
                                                    .font(.custom("Jost", size: 14).weight(.medium))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.white)
                                                    .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.27))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Image(systemName: "basketball.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 56, height: 56)
                                            .foregroundColor(.white)
                                            .padding(.trailing, 8)
                                    }
                                    .padding(16)
                                    .background(Color(red: 0.12, green: 0.16, blue: 0.27))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
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
                
                //                Color.black.opacity(0.05).ignoresSafeArea().zIndex(1)
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
            scheduleStore.start()
            if isLoggedIn { favoritesStore.start() }
        }
        .onChange(of: isLoggedIn) { loggedIn in
            if loggedIn { favoritesStore.start() } else { favoritesStore.stop() }
        }
    }
    
    private func asInt(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        return nil
    }
    
    private func teamName(for id: Int) -> String {
        // Adjust this to whatever your TeamsDirectory model exposes
        return teamsDir.team(id)?.name ?? "Team \(id)"
    }
    
    private func teamLogo(for id: Int) -> Image {
        if let img = UIImage(named: "\(id)") {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "shield.lefthalf.filled")
        }
    }
    
    @MainActor
    private func refresh() async {
        if selectedTab == "matches" {
            scheduleStore.stop()              // optional, to force a clean reload
            scheduleStore.start()
        } else if selectedTab == "favorites" {
            if isLoggedIn {
                favoritesStore.start()
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
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}
