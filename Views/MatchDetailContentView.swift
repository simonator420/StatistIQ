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
                    } else if selectedTab == "Games" {
                        gamesSection
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .onChange(of: selectedTab) { _ in
                
                    proxy.scrollTo("top", anchor: .top)
                
            }
        }
    }
}

private extension MatchDetailContentView {
    // MARK: - SUMMARY SECTION
    var summarySection: some View {
        VStack(spacing: 25) {
            winProbabilityCard
            predictedRangeCard
            expectedMarginCard
            overtimeCard
        }
//        .padding(.top, 25)
    }

    // MARK: 1. Win Probability
    var winProbabilityCard: some View {
        infoCard {
            headerWithInfo("Win Probability", text: """
                Win Probability represents the chance each team has to win the game.
                """)
            HStack(spacing: 120) {
                Text(vm.model?.homeWinText ?? "–")
                Text(vm.model?.awayWinText ?? "–")
            }
            .font(.custom("Jost", size: 28).weight(.medium))
            .foregroundColor(mainTextColor)
        }
    }

    // MARK: 2. Predicted Range
    var predictedRangeCard: some View {
        infoCard {
            headerWithInfo("Predicted Points Range", text: """
                Predicted Points Range shows the expected scoring interval for each team.
                """)
            HStack(spacing: 70) {
                Text(vm.model?.homeRangeText ?? "–")
                Text(vm.model?.awayRangeText ?? "–")
            }
            .font(.custom("Jost", size: 28).weight(.medium))
            .foregroundColor(mainTextColor)
        }
    }

    // MARK: 3. Expected Margin
    var expectedMarginCard: some View {
        infoCard {
            headerWithInfo("Expected Margin of Victory", text: """
                Expected Margin of Victory indicates the predicted point difference.
                """)

            HStack(spacing: 12) {
                expectedMarginDot
                Text(expectedMarginText)
                    .font(.custom("Jost", size: 28).weight(.medium))
                    .foregroundColor(mainTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    // MARK: 4. Overtime Probability
    var overtimeCard: some View {
        infoCard {
            headerWithInfo("Overtime Probability", text: """
                Chance the game reaches overtime.
                """)
            Text(vm.model?.overtimeProbabilityText(using: teams) ?? "–")
                .font(.custom("Jost", size: 28).weight(.medium))
                .foregroundColor(mainTextColor)
        }
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
            ) ?? Color.gray.opacity(0.3)

        let awayColor =
            pickTeamColor(
                primary: awayPrimaryHexOpp,
                secondary: awaySecondaryHex,
                opponentPrimary: homePrimaryHexOpp
            ) ?? Color.gray.opacity(0.3)

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
        .padding(.horizontal, 16)
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

    var expectedMarginDot: some View {
        let color: Color? = {
            guard
                let favId = vm.model?.expectedMarginTeamId,
                let favTeam = teams.team(favId)
            else { return nil }

            let primary = favTeam.primaryColor
            let secondary = favTeam.secondaryColor

            let opponentId = favId == vm.model?.homeId ? vm.model?.awayId : vm.model?.homeId
            let opponentPrimary = opponentId.flatMap { teams.team($0)?.primaryColor }

            return pickTeamColor(primary: primary, secondary: secondary, opponentPrimary: opponentPrimary)
        }()

        return Circle()
            .fill(color ?? Color.gray.opacity(0.4))
            .frame(width: 14, height: 14)
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
