import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct ProfilePage: View {
    @Binding var selectedTab: String
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: [String: Any]
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isFavoritesExpanded: Bool = false
    @StateObject private var favoritesStore = FavoritesStore()
    
    let fetchUserProfile: (String, @escaping ([String: Any]?) -> Void) -> Void
    
    var body: some View {
        Group {
            ScrollView {
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
                            .padding(.top, 15)
                            
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
                                            teamColorDot(for: tid)
                                            
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
                                
                                
                                ShareLink(item: URL(string: "https://simonator420.github.io/statistiq-legal/about.html")! ){
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
            .onAppear {
                if isLoggedIn { favoritesStore.start() }
            }
            .onChange(of: isLoggedIn) { logged in
                if logged { favoritesStore.start() } else { favoritesStore.stop() }
            }
        }
    }
    
    private func teamName(for id: Int) -> String {
        TeamsDirectory.shared.team(id)?.name ?? "Team \(id)"
    }
    private func teamLogo(for id: Int) -> Image {
        if let img = UIImage(named: "\(id)") {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "shield.lefthalf.filled")
        }
    }
    private func teamColorDot(for id: Int) -> some View {
        let team = TeamsDirectory.shared.team(id)
        let primary = team?.primaryColor
        let secondary = team?.secondaryColor

        let picked = pickTeamColor(primary: primary, secondary: secondary, opponentPrimary: nil)

        return Circle()
            .fill(picked)
            .frame(width: 16, height: 16)
    }

}
