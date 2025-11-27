import SwiftUI

struct GameCard: View {
    let homeId: Int?
    let awayId: Int?

    @ObservedObject private var teams = TeamsDirectory.shared

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)

            HStack {
                teamColumn(teamId: homeId)
                Spacer()
                teamColumn(teamId: awayId)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: – TEAM COLUMN
    @ViewBuilder
    private func teamColumn(teamId: Int?) -> some View {
        let team = teamId.flatMap { teams.team($0) }
        let primary = team?.primaryColor
        let secondary = team?.secondaryColor

        let color = pickTeamColor(
            primary: primary,
            secondary: secondary,
            opponentPrimary: nil
        )

        VStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 60, height: 4)
                .cornerRadius(2)

            Text(team?.name ?? "—")
                .font(.custom("Jost-SemiBold", size: 18))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
    }
}
