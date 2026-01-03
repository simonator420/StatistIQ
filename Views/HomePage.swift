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
    @State private var selectedTabIndex: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Color(red: 0.12, green: 0.16, blue: 0.27)
                    .ignoresSafeArea()
                    .frame(height: 0)
                TabView(selection: $selectedTabIndex) {
                    // Matches page with its TopBar
                    ZStack(alignment: .top) {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        VStack(spacing: 0) {
                            TopBarView(
                                selectedTab: .constant("matches"),
                                showLeagueSelection: $showLeagueSelection,
                                currentLeague: $currentLeague,
                                isLoggedIn: $isLoggedIn,
                                currentUser: $currentUser,
                                onUsernameChanged: { updated in
                                    self.currentUser["username"] = updated
                                }
                            )
                            
                            MatchesPage(
                                net: net,
                                currentLeague: $currentLeague,
                                scheduleStore: scheduleStore
                            )
                        }
                    }
                    .tag(0)
                    
                    
                    // Favorites page with its TopBar
                    ZStack(alignment: .top) {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            TopBarView(
                                selectedTab: .constant("favorites"),
                                showLeagueSelection: $showLeagueSelection,
                                currentLeague: $currentLeague,
                                isLoggedIn: $isLoggedIn,
                                currentUser: $currentUser,
                                onUsernameChanged: { updated in
                                    self.currentUser["username"] = updated
                                }
                            )
                            
                            FavoritesPage(
                                isLoggedIn: $isLoggedIn,
                                currentLeague: $currentLeague,
                                currentUser: $currentUser,
                                scheduleStore: scheduleStore,
                                fetchUserProfile: fetchUserProfile
                            )
                        }
                    }
                    .tag(1)

                    // Profile page with its TopBar
                    ZStack(alignment: .top) {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            TopBarView(
                                selectedTab: .constant("profile"),
                                showLeagueSelection: $showLeagueSelection,
                                currentLeague: $currentLeague,
                                isLoggedIn: $isLoggedIn,
                                currentUser: $currentUser,
                                onUsernameChanged: { updated in
                                    self.currentUser["username"] = updated
                                }
                            )
                            
                            ProfilePage(
                                selectedTab: $selectedTab,
                                isLoggedIn: $isLoggedIn,
                                currentUser: $currentUser,
                                fetchUserProfile: fetchUserProfile
                            )
                        }
                    }
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(
                    PageScrollBounceFix(
                        currentIndex: selectedTabIndex,
                        maxIndex: 2
                    )
                )
                .onChange(of: selectedTabIndex) { oldValue, newValue in
                    switch newValue {
                    case 0: selectedTab = "matches"
                    case 1: selectedTab = "favorites"
                    case 2: selectedTab = "profile"
                    default: break
                    }
                }
                .onChange(of: selectedTab) { oldValue, newValue in
                    let newIndex: Int
                    switch newValue {
                    case "matches": newIndex = 0
                    case "favorites": newIndex = 1
                    case "profile": newIndex = 2
                    default: return
                    }
                    
                    if newIndex != selectedTabIndex {
                        selectedTabIndex = newIndex
                    }
                }
                
                adBanner()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
            .padding(.bottom, 58)
            .padding(.top, 12)
    }
}

struct PageScrollBounceFix: UIViewRepresentable {
    let currentIndex: Int
    let maxIndex: Int

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = findScrollView(from: uiView) else { return }

            // Default
            scrollView.alwaysBounceVertical = false
            scrollView.isPagingEnabled = true

            if currentIndex == 0 {
                // zákaz swipu doleva
                scrollView.bounces = false
                scrollView.alwaysBounceHorizontal = false
            } else if currentIndex == maxIndex {
                // zákaz swipu doprava
                scrollView.bounces = false
                scrollView.alwaysBounceHorizontal = false
            } else {
                // prostřední stránka – normální chování
                scrollView.bounces = true
                scrollView.alwaysBounceHorizontal = true
            }
        }
    }

    private func findScrollView(from view: UIView) -> UIScrollView? {
        var current: UIView? = view
        for _ in 0..<12 {
            if let sv = current as? UIScrollView { return sv }
            if let found = current?.subviews.compactMap({ deepFindScrollView(in: $0) }).first(where: { $0 != nil }) ?? nil {
                return found
            }
            current = current?.superview
        }
        return nil
    }

    private func deepFindScrollView(in view: UIView) -> UIScrollView? {
        if let sv = view as? UIScrollView { return sv }
        for sub in view.subviews {
            if let found = deepFindScrollView(in: sub) { return found }
        }
        return nil
    }
}



#Preview {
    Homepage()
}

