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
                        // BENEFITS (white text, rounded)
                        VStack(spacing: 12) {

                            benefitCard(
                                icon: "star.fill",
                                title: "Favorites feed",
                                subtitle: "All your teams in one place."
                            )

                            benefitCard(
                                icon: "chart.bar.fill",
                                title: "AI predictions",
                                subtitle: "Win probabilities and expected margins."
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 15)

                        
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
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isFavoritesExpanded.toggle()
                            }
                        } label: {
                            manageFavoritesCard()
                        }
                        .buttonStyle(.plain)

                        
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
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color(colorScheme == .light ? .white : .systemGray6))
                                        )

                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(colorScheme == .light ? .white : .systemGray6))
                                    .shadow(
                                        color: .black.opacity(colorScheme == .light ? 0.08 : 0),
                                        radius: 8,
                                        x: 0,
                                        y: 2
                                    )
                            )
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
            .onChange(of: isLoggedIn) {
                if isLoggedIn {
                    favoritesStore.start()
                } else {
                    favoritesStore.stop()
                }
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
    
    private func benefitCard(icon: String, title: String, subtitle: String) -> some View {
            let mainTextColor =
                colorScheme == .light
                ? Color(red: 0.12, green: 0.16, blue: 0.27)
                : Color.white

            return HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mainTextColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Jost", size: 15).weight(.semibold))
                        .foregroundColor(mainTextColor)

                    Text(subtitle)
                        .font(.custom("Jost", size: 13))
                        .foregroundColor(mainTextColor.opacity(0.7))
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(colorScheme == .light ? .white : .systemGray6))
                    .shadow(
                        color: .black.opacity(colorScheme == .light ? 0.08 : 0),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
        }
    
    private func manageFavoritesCard() -> some View {
        let mainTextColor =
            colorScheme == .light
            ? Color(red: 0.12, green: 0.16, blue: 0.27)
            : Color.white

        return HStack {
            Text("Manage favorites")
                .font(.custom("Jost", size: 16).weight(.medium))
                .foregroundColor(mainTextColor)

            Spacer()

            Image(systemName: "chevron.right")
                .rotationEffect(.degrees(isFavoritesExpanded ? 90 : 0))
                .foregroundColor(mainTextColor)
                .font(.system(size: 16, weight: .semibold))
                .animation(.easeInOut(duration: 0.2), value: isFavoritesExpanded)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(colorScheme == .light ? .white : .systemGray6))
                .shadow(
                    color: .black.opacity(colorScheme == .light ? 0.08 : 0),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }




}
