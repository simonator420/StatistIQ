import SwiftUI
import FirebaseAuth

struct FavoritesPage: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentLeague: String
    @Binding var currentUser: [String: Any]
    @ObservedObject var scheduleStore: GamesScheduleStore
    let fetchUserProfile: (String, @escaping ([String: Any]?) -> Void) -> Void
    
    @ObservedObject private var teamsDir = TeamsDirectory.shared
    @StateObject private var favoritesStore = FavoritesStore()
    
    var body: some View {
        ScrollView {
            if !isLoggedIn {
                // Sign-in prompt (same visuals you had)
                VStack(spacing: 20) {
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
                    })) {
                        Text("Sign in")
                            .font(.custom("Jost", size: 16).weight(.medium))
                            .foregroundColor(.white)
                            .frame(width: 129, height: 40)
                            .background(Color(red: 0.12, green: 0.16, blue: 0.27))
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 119)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Logged-in favorites list (same selection logic)
                let favoriteTeamIds = favoritesStore.favorites
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
                    let calendar  = Calendar.current
                    let now       = Date()
                    let gameStart = scheduleStore.gameStart
                    let gameMeta  = scheduleStore.gameMeta
                    
                    let candidates: [(id: Int, start: Date, home: Int, away: Int)] =
                        favoriteGameIds.compactMap { gid -> (id: Int, start: Date, home: Int, away: Int)? in
                            guard let dt = gameStart[gid], let meta = gameMeta[gid] else { return nil }
                            guard now <= dt.addingTimeInterval(9_000) else { return nil } // 2.5h
                            return (id: gid, start: dt, home: meta.homeId, away: meta.awayId)
                        }
                        .sorted { $0.start < $1.start }
                    
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
                        let favoritesPresent: Set<Int> = Set(candidates.flatMap { [$0.home, $0.away] }).intersection(favoritesStore.favorites)
                        let pickedAgg = candidates.reduce(into: (covered: Set<Int>(), items: [(id: Int, start: Date)]())) { acc, g in
                            let introducesHomeFav = favoritesPresent.contains(g.home) && !acc.covered.contains(g.home)
                            let introducesAwayFav = favoritesPresent.contains(g.away) && !acc.covered.contains(g.away)
                            if introducesHomeFav || introducesAwayFav {
                                acc.items.append((id: g.id, start: g.start))
                                if favoritesPresent.contains(g.home) { acc.covered.insert(g.home) }
                                if favoritesPresent.contains(g.away) { acc.covered.insert(g.away) }
                            }
                        }
                        let picked = pickedAgg.items
                        
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
        .onAppear {
            TeamsDirectory.shared.loadIfNeeded()
            if isLoggedIn { favoritesStore.start() }
        }
        .onChange(of: isLoggedIn) { oldValue, newValue in
            if newValue { favoritesStore.start() } else { favoritesStore.stop() }
        }
        .refreshable {
            await refresh()
        }
    }
    
    @MainActor
    private func refresh() async {
        // Purely cosmetic pause; does not fetch/restart anything
        try? await Task.sleep(nanoseconds: 400_000_000)
    }

}
