import SwiftUI

struct MatchesPage: View {
    @ObservedObject var net: NetworkMonitor
    @Binding var currentLeague: String
    @ObservedObject var scheduleStore: GamesScheduleStore
    @ObservedObject private var teamsDir = TeamsDirectory.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !net.isConnected {
                        // offline message
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
                        if !teamsDir.isLoaded {
                            EmptyView()
                        } else if !scheduleStore.gameIds.isEmpty {
                            let wantNBA = (currentLeague == "NBA")
                            let filteredIds = scheduleStore.gameIds.filter { gid in
                                guard let meta = scheduleStore.gameMeta[gid],
                                      let home = teamsDir.team(meta.homeId),
                                      let away = teamsDir.team(meta.awayId) else {
                                    return false
                                }
                                let homeNBA = (home.nba_team == true)
                                let awayNBA = (away.nba_team == true)
                                return wantNBA ? (homeNBA && awayNBA) : (!homeNBA && !awayNBA)
                            }
                            
                            if filteredIds.isEmpty {
                                Text("No matches available for \(currentLeague)")
                                    .font(.custom("Jost-Medium", size: 18))
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                let calendar  = Calendar.current
                                let gameStart = scheduleStore.gameStart
                                let gameMeta  = scheduleStore.gameMeta
                                let games: [(id: Int, start: Date, home: Int, away: Int)] = scheduleStore.gameIds.compactMap { gid in
                                    guard let dt = gameStart[gid],
                                          let meta = gameMeta[gid],
                                          let home = teamsDir.team(meta.homeId),
                                          let away = teamsDir.team(meta.awayId) else {
                                        return nil
                                    }
                                    print("gid: \(gid)")
                                    
                                    let homeNBA = (home.nba_team == true)
                                    let awayNBA = (away.nba_team == true)
                                    let matchesLeague = wantNBA ? (homeNBA && awayNBA) : (!homeNBA && !awayNBA)
                                    
                                    guard matchesLeague else { return nil }
                                    
                                    return (id: gid, start: dt, home: meta.homeId, away: meta.awayId)
                                }
                                    .sorted { $0.start < $1.start }
                                
                                
                                
                                if !games.isEmpty {
                                    let pickedAgg = games.reduce(into: (covered: Set<Int>(), items: [(id: Int, start: Date)]())) { acc, g in
                                        if !acc.covered.contains(g.home) || !acc.covered.contains(g.away) {
                                            acc.items.append((id: g.id, start: g.start))
                                            acc.covered.insert(g.home)
                                            acc.covered.insert(g.away)
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
                                                .font(.custom("Jost", size: 16).weight(.medium))
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
                                } else {
                                    // fallback when no start times
                                    ForEach(Array(filteredIds.enumerated()), id: \.element) { _, gid in
                                        NavigationLink {
                                            MatchDetailView(gameId: gid)
                                                .toolbar(.hidden, for: .navigationBar)
                                                .navigationBarBackButtonHidden(true)
                                        } label: {
                                            MatchCard(gameId: gid)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        } else {
                            if scheduleStore.isLoading {
                                EmptyView()
                            } else {
                                Text("No matches available for \(currentLeague)")
                                    .font(.custom("Jost-Medium", size: 18))
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            }
                        }
                    }
                }
            }
            .refreshable {
                await refresh()
            }
            
            // Spinner while initial data loads
            if net.isConnected, (scheduleStore.isLoading || !teamsDir.isLoaded) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle()) // default system look
                    .scaleEffect(1.2)
                    .transition(.opacity)
                    .zIndex(2)
                    .allowsHitTesting(false)
            }
            
        }
        .onAppear {
            TeamsDirectory.shared.loadIfNeeded()
            // DO NOT call scheduleStore.start() here (it runs in Homepage)
        }
    }
    
    @MainActor
    private func refresh() async {
        scheduleStore.stop()
        scheduleStore.start()
        try? await Task.sleep(nanoseconds: 300_000_000)
    }
}
