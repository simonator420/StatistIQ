import SwiftUI

struct BottomBar: View {
    @Binding var selectedTab: String  // tracks active tab

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(height: 60)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: -4)

            HStack(spacing: 75) {
                // Matches
                Button(action: { selectedTab = "matches" }) {
                    VStack(spacing: 4) {
                        Image(systemName: "sportscourt.fill")
                            .resizable()
                            .frame(width: 30, height: 24)
                            .animation(.easeInOut(duration: 0.1), value: selectedTab)
                            .foregroundColor(selectedTab == "matches" ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                        Text("Matches")
                            .font(.custom("Jost-Medium", size: 12))
                            .foregroundColor(selectedTab == "matches" ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Favorites
                Button(action: { selectedTab = "favorites" }) {
                    VStack(spacing: 4) {
                        Image(systemName: "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .animation(.easeInOut(duration: 0.1), value: selectedTab)
                            .foregroundColor(selectedTab == "favorites" ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                        Text("Favorites")
                            .font(.custom("Jost-Medium", size: 12))
                            .foregroundColor(selectedTab == "favorites" ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Profile
                Button(action: { selectedTab = "profile" }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .animation(.easeInOut(duration: 0.1), value: selectedTab)
                            .foregroundColor(selectedTab == "profile" ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                        Text("Profile")
                            .font(.custom("Jost-Medium", size: 12))
                            .foregroundColor(selectedTab == "profile" ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 10)
        }
    }
}

#Preview {
    BottomBar(selectedTab: .constant("favorites"))
}
