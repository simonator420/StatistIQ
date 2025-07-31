import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Homepage: View {
    @State private var selectedTab: String = "matches"
    @State private var showLeagueSelection = false
    @State private var currentLeague = "NBA"  // default league
    @State private var isLoggedIn = false
    @State private var hasFavoriteMatches = false
    @State private var currentUser: [String: Any] = [:]
    
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
                        .frame(height: selectedTab == "profile" ? 250 : 60)
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
                                else if selectedTab == "profile" {
                                    VStack{
                                        HStack(){
                                            Text("Profile")
                                                .font(.custom("Jost-SemiBold", size: 22))
                                                .foregroundColor(Color.white)
                                            
                                            Spacer()
                                            
                                            Image("settings")
                                                .resizable()
                                                .frame(width: 24, height: 24)
                                                .padding(.horizontal, 24)
                                        }
                                        .padding(.leading, 24)
                                        
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Image("ellipse")
                                                    .resizable()
                                                    .frame(width: 103, height: 103)
                                                    .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                                                    .clipShape(Circle())
                                                
                                                Image(systemName: "person.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 48, height: 48)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Text(
                                                isLoggedIn
                                                ? (Auth.auth().currentUser?.displayName ?? (currentUser["username"] as? String ?? "User Name"))
                                                : "User Name"
                                            )
                                            .font(.custom("Jost", size: 18).weight(.medium))
                                            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                                            .padding(.top, 15)
                                        }
                                        .padding(.top, 5)
                                    }
                                }
                            }
                                .padding(.top, 15)
                                .padding(.leading, selectedTab == "profile" ? 0 : 24),
                            alignment: .topLeading
                        )
                    
                    
                    // Content: Show matches from selected league
                    ScrollView {
                        VStack(spacing: 16) {
                            if selectedTab == "matches" {
                                if let leagueMatches = matches[currentLeague], !leagueMatches.isEmpty {
                                    ForEach(Array(leagueMatches.enumerated()), id: \.element) { index, match in
                                        VStack(spacing: 0) {
                                            NavigationLink(destination: MatchDetailView()) {
                                                MatchCard()
                                                    .padding(.top, 16)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            if index == 0 {
                                                adBanner()
                                                    .padding(.top, 16)
                                            }
                                        }
                                    }
                                } else {
                                    VStack(spacing: 16) {
                                        adBanner()
                                            .padding(.top, 16)
                                        
                                        Text("No matches available for \(currentLeague)")
                                            .font(.custom("Jost-Medium", size: 18))
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                    }                                }
                            } else if selectedTab == "favorites" {
                                if !isLoggedIn {
                                    VStack(spacing: 20) {
                                        Image(systemName: "person.crop.circle")
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .padding(.top, 20)
                                        
                                        // Sign-in text
                                        Text("Sign in to view the matches of your favorite teams.")
                                            .font(.custom("Jost", size: 16).weight(.medium))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .frame(width: 270, alignment: .center)
                                        
                                        NavigationLink(destination: SignInView(onLogin: { isLoggedIn = true })) {
                                            signInButton()
                                        }
                                        .padding(.top, 10)
                                    }
                                    .padding(.top, 119)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                } else if isLoggedIn && !hasFavoriteMatches {
                                    VStack(spacing: 20) {
                                        // Calendar icon
                                        Image(systemName: "calendar")
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .padding(.top, 40)
                                        
                                        // No matches text
                                        Text("Check back later — we'll show upcoming matches as soon as they're scheduled.")
                                            .font(.custom("Jost", size: 16).weight(.medium))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .frame(width: 296, alignment: .center)
                                    }
                                    .padding(.top, 160)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                } else if isLoggedIn && hasFavoriteMatches {
                                    // TODO: Implement the display of favorite teams here
                                    Text("Favorites will be here")
                                        .font(.custom("Jost-Medium", size: 18))
                                        .padding(.top, 40)
                                }
                                
                            } else if selectedTab == "profile" {
                                if !isLoggedIn {
                                    VStack(spacing: 20) {
                                        Text("Sign in for the best user experience!")
                                            .font(.custom("Jost", size: 16).weight(.medium))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                                            .frame(width: 270, alignment: .center)
                                        
                                        NavigationLink(destination: SignInView(onLogin: { isLoggedIn = true })) {
                                            signInButton()
                                        }
                                        .padding(.top, 10)
                                        
                                    }
                                    .padding(.top, 60)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else if isLoggedIn {
                                    Button("Log out") {
                                        try? Auth.auth().signOut()
                                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                                        isLoggedIn = false
                                    }
                                }
                                
                            }
                        }
                    }
                    
                    if !isLoggedIn && (selectedTab == "favorites" || selectedTab == "profile") {
                        adBanner()
                            .padding(.bottom, 32)
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
            // Check Firebase or stored flag
            if Auth.auth().currentUser != nil || UserDefaults.standard.bool(forKey: "isLoggedIn") {
                isLoggedIn = true
                
                if let uid = Auth.auth().currentUser?.uid {
                    fetchUserProfile(uid: uid) { data in
                        if let data = data {
                            self.currentUser = data
                        }
                    }
                }
                
            } else {
                isLoggedIn = false
            }
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
    
    
    func adBanner() -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 0)
            .frame(height: 60)
            .padding(.horizontal, 16)
            .overlay(
                Text("Ad Banner")
                    .foregroundColor(.black) // Text color
                    .font(.custom("Jost-Medium", size: 16))
            )
    }
}


#Preview {
    Homepage()
}
