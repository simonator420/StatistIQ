import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Homepage: View {
    @State private var selectedTab: String = "matches"
    @State private var showLeagueSelection = false
    @State private var currentLeague = "NBA"  // default league
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var hasFavoriteMatches = false
    @State private var currentUser: [String: Any] = [:]
    @StateObject private var net = NetworkMonitor.shared
    @StateObject private var scheduleStore = GamesScheduleStore.shared
    @State private var userListener: ListenerRegistration?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme == .light ? Color.white : Color(.black))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Bar
                    TopBarView(
                        selectedTab: $selectedTab,
                        showLeagueSelection: $showLeagueSelection,
                        currentLeague: $currentLeague,
                        isLoggedIn: $isLoggedIn,
                        currentUser: $currentUser,
                        onUsernameChanged: { updated in
                            self.currentUser["username"] = updated
                        }
                    )
                    
                    ZStack {
                        MatchesPage(
                            net: net,
                            currentLeague: $currentLeague,
                            scheduleStore: scheduleStore
                        )
                        .opacity(selectedTab == "matches" ? 1 : 0)
                                .allowsHitTesting(selectedTab == "matches")
//                                .animation(.easeInOut(duration: 0.22), value: selectedTab)
                        
                        FavoritesPage(
                            isLoggedIn: $isLoggedIn,
                            currentLeague: $currentLeague,
                            currentUser: $currentUser,
                            scheduleStore: scheduleStore,
                            fetchUserProfile: fetchUserProfile
                        )
                        .opacity(selectedTab == "favorites" ? 1 : 0)
                                .allowsHitTesting(selectedTab == "favorites")
//                                .animation(.easeInOut(duration: 0.22), value: selectedTab)
                        ProfilePage(
                            selectedTab: $selectedTab,
                            isLoggedIn: $isLoggedIn,
                            currentUser: $currentUser,
                            fetchUserProfile: fetchUserProfile
                        )
                        .opacity(selectedTab == "profile" ? 1 : 0)
                                .allowsHitTesting(selectedTab == "profile")
//                                .animation(.easeInOut(duration: 0.22), value: selectedTab)
                    }
//                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    
                    adBanner()
                    
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    BottomBar(selectedTab: $selectedTab)
                }
                    .ignoresSafeArea(edges: .bottom),
                alignment: .bottom
            )
            
            // Offline overlay
            .overlay(
                Group {
                    if !net.isConnected {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)

                            Text("No internet connection")
                                .font(.custom("Jost", size: 17).weight(.semibold))
                                .foregroundColor(.white)

                            Text("Please check your network settings.")
                                .font(.custom("Jost", size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .transition(.opacity)
                        .zIndex(5)
                    }
                },
                alignment: .top
            )

            
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
                        
                        Color.black.opacity(0.5)
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
        
        .onAppear {
            scheduleStore.start()
            // Check Firebase or stored flag
            if Auth.auth().currentUser != nil || UserDefaults.standard.bool(forKey: "isLoggedIn") {
                isLoggedIn = true
                
                if let uid = Auth.auth().currentUser?.uid {
                    userListener?.remove()
                    userListener = Firestore.firestore()
                        .collection("users")
                        .document(uid)
                        .addSnapshotListener { snap, _ in
                            if let data = snap?.data() {
                                self.currentUser = data
                            }
                        }
                }
                
            } else {
                isLoggedIn = false
            }
        }
        .onDisappear {
            userListener?.remove()
            userListener = nil
        }
        
    }
    
    func fetchUserProfile(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch user: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(snapshot?.data())
        }
    }
    
    func signInButton() -> some View {
        Text("Sign in")
            .font(.custom("Jost", size: 16).weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .frame(width: 129, height: 40)
            .background(Color(red: 0.12, green: 0.16, blue: 0.27))
            .cornerRadius(10)
    }
    
    
//    func adBanner() -> some View {
//        Rectangle()
//            .fill(Color.gray)
//            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
//            .frame(height: 60)
//        //            .padding(.horizontal, 16)
//            .overlay(
//                Text("Ad Banner")
//                    .foregroundColor(.black) // Text color
//                    .font(.custom("Jost-Medium", size: 16))
//            )
//    }
    
    func formattedJoinDate(from timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else { return "" }
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Joined on \(formatter.string(from: date))"
    }
    
    func adBanner() -> some View {
        BannerAdView(adUnitID: "ca-app-pub-6108216778743846/4562365415")
            .frame(height: 50)
            .padding(.bottom, 48)
    }
}

#Preview {
    Homepage()
}
