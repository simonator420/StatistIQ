import SwiftUI

struct BottomBar: View {
    @Binding var selectedTab: String  // tracks active tab

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.98, green: 0.98, blue: 0.96))
                .frame(height: 78)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: -4)

            HStack(spacing: 60) {
                // Matches
                Button(action: { selectedTab = "matches" }) {
                    VStack(spacing: 4) {
                        Image(systemName: "sportscourt.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == "matches" ? Color(red: 0.85, green: 0.23, blue: 0.23) : Color(red: 0.12, green: 0.16, blue: 0.27))
                        Text("Matches")
                            .font(.custom("Jost-Medium", size: 12))
                            .foregroundColor(selectedTab == "matches" ? Color(red: 0.85, green: 0.23, blue: 0.23) : Color(red: 0.12, green: 0.16, blue: 0.27))
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Favorites
                Button(action: { selectedTab = "favorites" }) {
                    VStack(spacing: 4) {
                        Image(systemName: "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == "favorites" ? Color(red: 0.85, green: 0.23, blue: 0.23) : Color(red: 0.12, green: 0.16, blue: 0.27))
                        Text("Favorites")
                            .font(.custom("Jost-Medium", size: 12))
                            .foregroundColor(selectedTab == "favorites" ? Color(red: 0.85, green: 0.23, blue: 0.23) : Color(red: 0.12, green: 0.16, blue: 0.27))
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Profile
                Button(action: { selectedTab = "profile" }) {
                    VStack(spacing: 4) {
                        Image(systemName: "person")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedTab == "profile" ? Color(red: 0.85, green: 0.23, blue: 0.23) : Color(red: 0.12, green: 0.16, blue: 0.27))
                        Text("Profile")
                            .font(.custom("Jost-Medium", size: 12))
                            .foregroundColor(selectedTab == "profile" ? Color(red: 0.85, green: 0.23, blue: 0.23) : Color(red: 0.12, green: 0.16, blue: 0.27))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    BottomBar(selectedTab: .constant("favorites"))
}
