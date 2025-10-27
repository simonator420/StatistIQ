import SwiftUI

struct BottomBar: View {
    @Binding var selectedTab: String
    @Environment(\.colorScheme) private var colorScheme
    
    // TODO Smaller icons, more space below them, less space above them
    var body: some View {
        ZStack {
            // Adaptivní pozadí + tenká horní linka
            Color(colorScheme == .light ? Color.white : Color(.systemGray6))
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    Rectangle()
                        .fill(Color(.separator).opacity(0.6))
                        .frame(height: 0.5),
                    alignment: .top
                )

            HStack(spacing: 70) {
                tab(icon: "sportscourt.fill", title: "Matches", key: "matches")
                tab(icon: "star",             title: "Favorites", key: "favorites")
                tab(icon: "person",           title: "Profile",   key: "profile")
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 50) // rezerva nad home indikátorem
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
    }

    @ViewBuilder
    private func tab(icon: String, title: String, key: String) -> some View {
        Button { selectedTab = key } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                    .foregroundColor(selectedTab == key ? .primary : .secondary)
                Text(title)
                    .font(.custom("Jost-Medium", size: 10))
                    .foregroundColor(selectedTab == key ? .primary : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BottomBar(selectedTab: .constant("favorites"))
}
