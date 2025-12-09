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
        ScrollViewReader { proxy in
            
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 20)
                        .id("top")
                    if selectedTab == "Summary" {
                        summarySection
                    } else if selectedTab == "Head-to-Head" {
                        gamesSection
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .onChange(of: selectedTab) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }
}

private extension MatchDetailContentView {
    // MARK: - SUMMARY SECTION
    var summarySection: some View {
        VStack(spacing: 20) {
            winProbabilityCard
            predictedRangeCard
            expectedMarginCard
            overtimeCard
            predictionSummaryCard
        }
//        .padding(.top, 25)
    }

    // MARK: 1. Win Probability
    var winProbabilityCard: some View {
        infoCard {
            headerWithInfo("Win Probability", text: """
                Win Probability represents the chance each team has to win the game, based on factors like recent form, player performance, injuries, and historical matchups.
                                                        
                It's calculated using AI models trained on real game data and updated for every matchup.
                
                A higher percentage means the team is more likely to win — but upsets are always possible.
                """)
            HStack(spacing: 120) {
                Text(vm.model?.homeWinText ?? "–")
                Text(vm.model?.awayWinText ?? "–")
            }
            .font(.custom("Jost", size: 22).weight(.medium))
            .foregroundColor(mainTextColor)
        }
    }

    // MARK: 2. Predicted Range
    var predictedRangeCard: some View {
        infoCard {
            headerWithInfo("Predicted Points Range", text: """
                Predicted Points Range shows the expected scoring interval for each team based on statistical models.
                                                        
                These predictions take into account factors such as offensive and defensive efficiency, pace of play, player availability, and historical matchups.
                
                The actual score may vary, but this range provides an estimate of where the final points are most likely to fall.
                """)
            HStack(spacing: 70) {
                Text(vm.model?.homeRangeText ?? "–")
                Text(vm.model?.awayRangeText ?? "–")
            }
            .font(.custom("Jost", size: 22).weight(.medium))
            .foregroundColor(mainTextColor)
        }
    }

    // MARK: 3. Expected Margin
    var expectedMarginCard: some View {
        infoCard {
            headerWithInfo("Expected Margin of Victory", text: """
                Expected Margin of Victory indicates how many points a team is predicted to win by, on average, according to the model.
                                            
                It is calculated using factors like team strength, recent performance, player matchups, and game location.
                                                        
                A positive margin favors the listed team, while a negative margin would favor their opponent. The larger the margin, the more dominant the expected performance.
                """)

            if let m = vm.model {
                let fav = expectedMarginLabel(
                    home: m.winHome ?? 0,
                    away: m.winAway ?? 0,
                    homeCode: m.homeId.flatMap { teams.team($0)?.name } ?? "",
                    awayCode: m.awayId.flatMap { teams.team($0)?.name } ?? "",
                    marginFavTeamId: m.expectedMarginTeamId,
                    marginValue: m.expectedMarginValue
                )

                HStack(spacing: 12) {
                    expectedMarginDot(for: fav.teamId)
                    Text(fav.text ?? "–")
                        .font(.custom("Jost", size: 22).weight(.medium))
                        .foregroundColor(mainTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
    }

    // MARK: 4. Overtime Probability
    var overtimeCard: some View {
        infoCard {
            headerWithInfo("Overtime Probability", text: """
                Overtime Probability shows the chance the game is tied after regulation.
                                                
                It’s derived from our predicted score-margin distribution.
                
                A higher value means a tighter matchup; overtime is rare, so most games are in the low single digits.
                """)
            Text(vm.model?.overtimeProbabilityText(using: teams) ?? "–")
                .font(.custom("Jost", size: 22).weight(.medium))
                .foregroundColor(mainTextColor)
        }
    }
    
    var predictionSummaryCard: some View {
        predictionSummaryCardView(vm.model?.predictionSummary)
    }


    // MARK: - GAMES SECTION
    var gamesSection: some View {
        VStack(spacing: 25) {
            if vm.h2h.isEmpty {
                Text("No recent head-to-head games found.")
                    .font(.custom("Jost", size: 15).weight(.medium))
                    .foregroundColor(.gray)
                    .padding(.top, 25)
            } else {
                ForEach(vm.h2h) { g in
                    pastGameRow(g)
                }
            }
        }
//        .padding(.top, 25)
    }

    @ViewBuilder
    private func pastGameRow(_ g: H2HGame) -> some View {
        let homeTeam = teams.team(g.homeId)
        let awayTeam = teams.team(g.awayId)
        let homeAbbr = homeTeam?.code ?? String(g.homeId)
        let awayAbbr = awayTeam?.code ?? String(g.awayId)
        let homeScore = g.homeScore.map(String.init) ?? "-"
        let awayScore = g.awayScore.map(String.init) ?? "-"
        let date = g.startTime?.asShortDate ?? "—"
        let venue = g.venue.map { "@ \($0)" } ?? "—"
        
        let homePrimaryHex = homeTeam?.primaryColor
        let homeSecondaryHex = homeTeam?.secondaryColor
        let awayPrimaryHex = awayTeam?.primaryColor

        let awayPrimaryHexOpp = awayTeam?.primaryColor
        let awaySecondaryHex = awayTeam?.secondaryColor
        let homePrimaryHexOpp = homeTeam?.primaryColor

        let homeColor =
            pickTeamColor(
                primary: homePrimaryHex,
                secondary: homeSecondaryHex,
                opponentPrimary: awayPrimaryHex
            )

        let awayColor =
            pickTeamColor(
                primary: awayPrimaryHexOpp,
                secondary: awaySecondaryHex,
                opponentPrimary: homePrimaryHexOpp
            )

        PastGameCard(
            homePrimaryColor: homeColor,
            awayPrimaryColor: awayColor,
            homeId: g.homeId,
            awayId: g.awayId,
            homeAbbr: homeAbbr,
            awayAbbr: awayAbbr,
            homeScore: homeScore,
            awayScore: awayScore,
            date: date,
            venue: venue
        )
    }
}

private extension MatchDetailContentView {
    // MARK: - Shared UI Helpers

    var mainTextColor: Color {
        colorScheme == .light
        ? Color(red: 0.12, green: 0.16, blue: 0.27)
        : .white
    }

    func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) {
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal, 12)
    }

    func headerWithInfo(_ title: String, text: String) -> some View {
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
    }
    
    func predictionSummaryCardView(_ text: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Match Preview")
                .font(.custom("Jost", size: 15).weight(.medium))
                .foregroundColor(.gray)

            Text(text ?? "No preview available.")
                .font(.custom("Jost", size: 15).weight(.light))
                .foregroundColor(mainTextColor.opacity(0.75))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
}

private extension MatchDetailContentView {
    // MARK: - Expected Margin Helpers

    var expectedMarginText: String {
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

    private func expectedMarginDot(for teamId: Int?) -> some View {
        guard
            let tid = teamId,
            let t = teams.team(tid)
        else {
            return Circle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 14, height: 14)
        }

        let opponentId = tid == vm.model?.homeId ? vm.model?.awayId : vm.model?.homeId
        let opponentPrimary = opponentId.flatMap { teams.team($0)?.primaryColor }

        let color = pickTeamColor(
            primary: t.primaryColor,
            secondary: t.secondaryColor,
            opponentPrimary: opponentPrimary
        )

        return Circle()
            .fill(color)
            .frame(width: 14, height: 14)
    }
    
    private func expectedMarginLabel(
        home: Double,
        away: Double,
        homeCode: String,
        awayCode: String,
        marginFavTeamId: Int?,
        marginValue: Double?
    ) -> (teamId: Int?, text: String?) {
        
        // 1 — If marginValue exists → use same logic as MatchCard
        if let val = marginValue {
            let ab = val >= 0 ? homeCode : awayCode
            let team = val >= 0 ? vm.model?.homeId : vm.model?.awayId
            
            let absVal = abs(val)
            let number = absVal.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(absVal.rounded(.up)))
            : String(format: "%.0f", absVal.rounded(.up))
            
            let sign = val >= 0 ? "+" : "−"
            return (team, "\(sign)\(number) \(ab)")
        }
        
        // 2 — Otherwise fallback to win-probability favorite (MatchCard behavior)
        let h = max(0, min(1, home))
        let a = max(0, min(1, away))
        guard h != a else { return (nil, nil) }
        
        let favIsHome = h > a
        let pts = Int((abs(h - a) * 100).rounded())
        return (
            favIsHome ? vm.model?.homeId : vm.model?.awayId,
            favIsHome ? "+\(pts) \(homeCode)" : "+\(pts) \(awayCode)"
        )
    }
}

// MARK: - Date Extension
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
