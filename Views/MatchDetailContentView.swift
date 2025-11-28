import SwiftUI
import FirebaseFirestore
import Foundation

struct MatchDetailContentView: View {
    @ObservedObject var vm: MatchDetailViewModel
    @ObservedObject var teams: TeamsDirectory
    @Binding var selectedTab: String
    @Binding var showInfoSheet: Bool
    @Binding var infoText: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            
            VStack(spacing: 15) {
                if selectedTab == "Summary" {
                    Group {
                        // Win Probability
                        VStack(spacing: 5) {
                            headerWithInfo("Win Probability", text: """
                                        Win Probability represents the chance each team has to win the game, based on factors like recent form, player performance, injuries, and historical matchups.
                                        
                                        It's calculated using AI models trained on real game data and updated for every matchup.
                                        
                                        A higher percentage means the team is more likely to win — but upsets are always possible.
                                        """)
                            
                            HStack(spacing: 120) {
                                Text(vm.model?.homeWinText ?? "–")
                                Text(vm.model?.awayWinText ?? "–")
                            }
                            .font(.custom("Jost", size: 28).weight(.medium))
                            .foregroundColor(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            // lighter than black in dark mode, light gray in light mode
                            Color(.secondarySystemBackground)
                        )
                        .cornerRadius(14)
                        .padding(.top, 25)
                        .padding(.horizontal, 16)
                        
                        // Predicted Points Range
                        VStack(spacing: 10) {
                            headerWithInfo("Predicted Points Range", text: """
                                        Predicted Points Range shows the expected scoring interval for each team based on statistical models.
                                        
                                        These predictions take into account factors such as offensive and defensive efficiency, pace of play, player availability, and historical matchups.
                                        
                                        The actual score may vary, but this range provides an estimate of where the final points are most likely to fall.
                                        """)
                            HStack(spacing: 70) {
                                Text(vm.model?.homeRangeText ?? "–")
                                Text(vm.model?.awayRangeText ?? "–")
                            }
                            .font(.custom("Jost", size: 28).weight(.medium))
                            .foregroundColor(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            // lighter than black in dark mode, light gray in light mode
                            Color(.secondarySystemBackground)
                        )
                        .cornerRadius(14)
                        .padding(.top, 25)
                        .padding(.horizontal, 16)
                        
                        // Expected Margin
                        VStack(spacing: 10) {
                            headerWithInfo("Expected Margin of Victory", text: """
                            Expected Margin of Victory indicates how many points a team is predicted to win by, on average, according to the model.
                            
                            It is calculated using factors like team strength, recent performance, player matchups, and game location.
                                                                    
                            A positive margin favors the listed team, while a negative margin would favor their opponent. The larger the margin, the more dominant the expected performance.
                            """)
                            HStack(spacing: 12) {
                                
                                // === DOT WITH SAME PICK COLOR LOGIC ===
                                if let favId = vm.model?.expectedMarginTeamId,
                                   let favTeam = teams.team(favId)
                                {
                                    let primary = favTeam.primaryColor
                                    let secondary = favTeam.secondaryColor
                                    
                                    let opponentId =
                                    favId == vm.model?.homeId ? vm.model?.awayId : vm.model?.homeId
                                    let opponentPrimary = opponentId.flatMap { teams.team($0)?.primaryColor }
                                    
                                    let pickedColor = pickTeamColor(
                                        primary: primary,
                                        secondary: secondary,
                                        opponentPrimary: opponentPrimary
                                    )
                                    
                                    Circle()
                                        .fill(pickedColor)
                                        .frame(width: 14, height: 14)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.4))
                                        .frame(width: 14, height: 14)
                                }
                                
                                Text(expectedMargin(vm: vm, teams: teams))
                                    .font(.custom("Jost", size: 28).weight(.medium))
                                    .foregroundColor(
                                        colorScheme == .light
                                        ? Color(red: 0.12, green: 0.16, blue: 0.27)
                                        : Color.white
                                    )
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            // lighter than black in dark mode, light gray in light mode
                            Color(.secondarySystemBackground)
                        )
                        .cornerRadius(14)
                        .padding(.top, 25)
                        .padding(.horizontal, 16)
                        
                        VStack(spacing: 10) {
                            headerWithInfo("Overtime Probability", text: """
                                Overtime Probability shows the chance the game is tied after regulation.
                                
                                It’s derived from our predicted score-margin distribution.
                                
                                A higher value means a tighter matchup; overtime is rare, so most games are in the low single digits.
                                """)
                            Text(vm.model?.overtimeProbabilityText(using: teams) ?? "–")
                                .font(.custom("Jost", size: 28).weight(.medium))
                                .foregroundColor(colorScheme == .light ? Color(red: 0.12, green: 0.16, blue: 0.27) : Color.white)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            // lighter than black in dark mode, light gray in light mode
                            Color(.secondarySystemBackground)
                        )
                        .cornerRadius(14)
                        .padding(.top, 25)
                        .padding(.horizontal, 16)
                        
                        // Key Players – keep your placeholder or wire up later
                    }
                    Spacer()
                    
                } else if selectedTab == "Games" {
                    VStack(spacing: 25) {
                        if vm.h2h.isEmpty {
                            
                            Text("No recent head-to-head games found.")
                                .font(.custom("Jost", size: 15).weight(.medium))
                                .foregroundColor(.gray)
                                .padding(.top, 25)
                        } else {
                            ForEach(vm.h2h) { g in
                                PastGameCard(
                                    homeLogo: "\(g.homeId)",   // assets named like "132"
                                    awayLogo: "\(g.awayId)",
                                    homeScore: g.homeScore.map(String.init) ?? "-",
                                    awayScore: g.awayScore.map(String.init) ?? "-",
                                    date: g.startTime?.asShortDate ?? "—",
                                    venue: g.venue.map { "@ \($0)" } ?? "—"
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 25.0)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func expectedMargin(vm: MatchDetailViewModel, teams: TeamsDirectory) -> String {
        guard
            let value = vm.model?.expectedMarginValue,
            let favId = vm.model?.expectedMarginTeamId,
            let teamName = teams.team(favId)?.name
        else { return "–" }
        
        let positive = abs(value)
        
        let formatted = positive.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(positive))
        : String(format: "%.1f", positive)
        
        return "+\(formatted) \(teamName)"
    }
    
    private func headerWithInfo(_ title: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.custom("Jost", size: 15).weight(.medium))
                .foregroundColor(.gray)
            Button {
                infoText = text
                showInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.gray)
            }
        }
        //        .padding(.top, 25.0)
    }
}

// If you don't already have this elsewhere in your project:
private extension Date {
    var asShortDate: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: self)
    }
}
