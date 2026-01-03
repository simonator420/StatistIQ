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
    @State private var showMatchOnboarding: Bool = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        Color(red: 0.12, green: 0.16, blue: 0.27)
            .frame(maxWidth: .infinity)
            .frame(height: selectedTab == "profile" ? (isLoggedIn ? 265 : 250) : 60)
            .ignoresSafeArea(.all, edges: .top)
            .overlay(
                Group {
                    if selectedTab == "matches" {
                        HStack(spacing: 12) {
                            Text("Upcoming Games")
                                .font(.custom("Jost-SemiBold", size: 22))
                                .foregroundColor(.white)
                                .onAppear {
                                    currentLeague = "NBA"
                                }

                            Spacer()
                            
                            // INFO ICON (opens onboarding)
                            Button {
                                showMatchOnboarding = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.trailing, 19)
                                    .padding(.top, 3)
                            }
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
                        }
                    }
                }
                    .padding(.top, 13)
                    .padding(.leading, selectedTab == "profile" ? 0 : 24),
                alignment: .topLeading
            )
            .fullScreenCover(isPresented: $showMatchOnboarding) {
                MatchCardOnboardingView {
                    showMatchOnboarding = false
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfile(
                    initialUsername: currentUser["username"] as? String ?? "",
                    onSaved: { updated in
                        onUsernameChanged(updated)
                    }
                )
            }
    }
    
    private func formattedJoinDate(from timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else { return "" }
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Joined on \(formatter.string(from: date))"
    }
}
