import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TopBarView: View {
    @Binding var selectedTab: String
    @Binding var showLeagueSelection: Bool
    @Binding var currentLeague: String
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: [String: Any]
    
    // When username changes in Settings
    var onUsernameChanged: (String) -> Void = { _ in }
    
    @State private var rotate: Double = 0
    @State private var showEditProfile: Bool = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Color(red: 0.12, green: 0.16, blue: 0.27)
            .ignoresSafeArea(.all, edges: .top)
            .frame(height: selectedTab == "profile" ? (isLoggedIn == true ? 265 : 250) : 60)
            .overlay(
                Group {
                    if selectedTab == "matches" {
                        Button {
                            let spin = reduceMotion ? 0.0 : 0.25
                            withAnimation(.linear(duration: spin)) {
                                rotate = (rotate + 180).truncatingRemainder(dividingBy: 360)
                            }
                            
                            let t = Transaction(animation: nil)
                            withTransaction(t) {
                                currentLeague = (currentLeague == "NBA") ? "Euroleague" : "NBA"
                            }
                        } label: {
                            HStack(spacing: 10) {
                                // Group logo + name as one semantic chunk
                                Image("\(currentLeague)_logo".lowercased())
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                
                                Text(currentLeague)
                                    .font(.custom("Jost-SemiBold", size: 22))
                                    .foregroundColor(.white)
                                    .contentTransition(.identity)
                                    .animation(nil, value: currentLeague)
                                
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(rotate))
                                    .accessibilityLabel("Toggle league")
                            }
                            .contentShape(Rectangle())               // bigger tap target
                        }
                    } else if selectedTab == "favorites" {
                        Text("Favorites")
                            .font(.custom("Jost-SemiBold", size: 22))
                            .foregroundColor(.white)
                        
                    } else if selectedTab == "profile" {
                        VStack {
                            HStack {
                                Text("Profile")
                                    .font(.custom("Jost-SemiBold", size: 22))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                NavigationLink(
                                    destination: SettingsView(onUsernameChanged: { updated in
                                        onUsernameChanged(updated)
                                    })
                                ) {
                                    Image("settings")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .padding(.horizontal, 24)
                                }
                            }
                            .padding(.leading, 24)
                            
                            VStack(spacing: 8) {
//                                Image("avatar_icon")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 160, height: 160)
//                                    .foregroundColor(.white)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    
                                    Image("user_outline")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 96, height: 96)
                                        .symbolRenderingMode(.monochrome)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.top, 10)
                                    
                                    if isLoggedIn {
                                        Button {
                                            showEditProfile = true
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 25, weight: .semibold))
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, Color(red: 0.12, green: 0.16, blue: 0.27))
                                                .shadow(radius: 1)
                                        }
                                        .offset(x: 10, y: 10)
                                        .accessibilityLabel("Edit profile")
                                    }
                                }
                                NavigationLink(
                                    destination: EditProfile(
                                        initialUsername: currentUser["username"] as? String ?? "",
                                        onSaved: { updated in
                                            onUsernameChanged(updated)
                                        }
                                    ),
                                    isActive: $showEditProfile
                                ) { EmptyView() }.hidden()
                                
                                if isLoggedIn {
                                    Text(currentUser["username"] as? String ?? "")
                                        .font(.custom("Jost", size: 18).weight(.medium))
                                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                                    
                                    if let timestamp = currentUser["createdAt"] as? Timestamp {
                                        Text(formattedJoinDate(from: timestamp))
                                            .font(.custom("Jost", size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                } else {
                                    Text("Smart predictions, winning insights")
                                        .font(.custom("Jost", size: 18).weight(.medium))
                                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                                        .padding(.top, 15)
                                }
                            }
                            //                            .padding(.top, 5)
                        }
                    }
                }
                    .padding(.top, 10)
                    .padding(.leading, selectedTab == "profile" ? 0 : 24),
                alignment: .topLeading
            )
    }
    
    // Same formatting helper as in Homepage, kept local for convenience
    private func formattedJoinDate(from timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else { return "" }
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Joined on \(formatter.string(from: date))"
    }
}

#Preview {
    @State var selectedTab = "profile"
    @State var showLeagueSelection = false
    @State var currentLeague = "NBA"
    @State var isLoggedIn = true
    @State var currentUser: [String: Any] = [
        "username": "simonator420",
        "createdAt": Timestamp(date: Date())
    ]
    
    return NavigationStack {
        TopBarView(
            selectedTab: $selectedTab,
            showLeagueSelection: $showLeagueSelection,
            currentLeague: $currentLeague,
            isLoggedIn: $isLoggedIn,
            currentUser: $currentUser
        )
    }
}
