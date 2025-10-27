import SwiftUI
import FirebaseFirestore

struct MatchCard: View {
    let gameId: Int
    
    @StateObject private var vm = MatchCardViewModel()
    @ObservedObject private var teams = TeamsDirectory.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private let corner: CGFloat = 14
    private let hPad: CGFloat = 16
    private let vPad: CGFloat = 10
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                //.fill(Color(.systemBackground))
                .fill(Color(colorScheme == .light ? Color.white : Color(.systemGray6)))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                .frame(height: 165)
                .padding(.horizontal, 12)
            
            if let m = vm.model {
                let home = m.winHome ?? 0     // 0…1
                let away = m.winAway ?? 0     // 0…1
                
                VStack(spacing: 8) {
                    // HEADER — time · venue
                    HStack(spacing: 6) {
                        if let start = m.startTime {
                            Text(shortTime(start))
                                .font(.custom("Jost", size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("·")
                            .font(.custom("Jost", size: 13))
                            .foregroundColor(.secondary)
                        
                        if let homeId = m.homeId,
                               let arena = teams.arena(for: homeId),
                               let city = teams.city(for: homeId) {
                                Text("\(venueShort("\(arena), \(city)"))")
                                    .font(.custom("Jost", size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        
                        //                        Spacer()
                        //                        Text("Upcoming")
                        //                            .font(.system(size: 11, weight: .semibold))
                        //                            .foregroundColor(.secondary)
                        //                            .padding(.horizontal, 8)
                        //                            .padding(.vertical, 4)
                        //                            .background(Color.secondary.opacity(0.12))
                        //                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, hPad)
                    .padding(.top, vPad)
                    
                    Divider().opacity(0.12).padding(.horizontal, hPad)
                    
                    // TEAMS ROW — menší loga, zkratky
                    HStack(alignment: .center) {
                        teamCell(teamId: m.homeId, fallback: "HOME")
                        
                        VStack(spacing: 4) {
                            Text("–")
                                .font(.custom("Jost", size: 14))
                                .foregroundColor(.secondary)
                            if let edge = edgeText(home: home,
                                                   away: away,
                                                   homeCode: code(m.homeId),
                                                   awayCode: code(m.awayId),
                                                   marginFavTeamId: m.marginFavTeamId,
                                                   marginValue: m.marginValue
                            ) {
                                Text(edge)
                                    .font(.custom("Jost", size: 11))
                                    .foregroundColor(.secondary)
                                //                                    .padding(.horizontal, 8)
                                //                                    .padding(.vertical, 3)
                                    .padding(10)
                                    .background(Color.secondary.opacity(0.10))
                                    .clipShape(Capsule())
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                        .layoutPriority(2)
                        
                        teamCell(teamId: m.awayId, fallback: "AWAY", rightAligned: true)
                    }
                    .padding(.horizontal, hPad)
                    
                    // PROBABILITY BAR — kompaktní
                    VStack(spacing: 6) {
                        ProbBar(homePct: home, awayPct: away)
                            .frame(height: 10)
                            .clipShape(Capsule())
                            .padding(.horizontal, 6)
                        
                        HStack {
                            Text("\(abbr(m.homeId)) \(m.homeWinText)")
                                .font(.custom("Jost", size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                            Spacer()
                            Text("\(m.awayWinText) \(abbr(m.awayId))")
                                .font(.custom("Jost", size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, vPad)
                }
            }
//            else {
//                // Loading state with rotating circle
//                VStack {
//                    Spacer()
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
//                        .scaleEffect(1.4) // makes it a bit bigger
//                    Spacer()
//                }
//                .frame(height: 155)
//                .padding(.horizontal, 12)
//            }
        }
        .onAppear {
            teams.loadIfNeeded()
            vm.bind(gameId: gameId)
        }
        .onDisappear { vm.stop() }
    }
    
    // MARK: - Helpers
    
    private func teamCell(teamId: Int?, fallback: String, rightAligned: Bool = false) -> some View {
        let ab = abbr(teamId)
        let logoImg = logo(for: teamId)
        
        return VStack(spacing: 10) {
            logoImg
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .frame(maxWidth: 110, alignment: rightAligned ? .trailing : .leading)
//                .shadow(color: .white.opacity(1), radius: 0.9, x: 0, y: 0)

            Text(ab.isEmpty ? fallback : ab)
                .font(.custom("Jost", size: 15).weight(.light))
        
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(minWidth: 80, maxWidth: .infinity, alignment: rightAligned ? .trailing : .leading)
                .padding(.horizontal, 6)
        }
//        .frame(maxWidth: .infinity, alignment: rightAligned ? .trailing : .leading)
    }
    
    private func abbr(_ teamId: Int?) -> String {
        guard let id = teamId else { return "" }
        return teams.abbreviation(for: id) ?? ""
    }
    
    private func code(_ teamId: Int?) -> String {
        guard let id = teamId else { return "" }
        return teams.code(for: id) ?? ""
    }
    
    private func logo(for teamId: Int?) -> Image {
        if let id = teamId, let img = UIImage(named: "\(id)") {
            return Image(uiImage: img)
        } else {
            return Image(systemName: "shield.lefthalf.filled")
            
        }
    }
    
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private func shortTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }

    
    private func venueShort(_ venue: String) -> String {
        venue
            .replacingOccurrences(of: "Arena", with: "A.")
            .replacingOccurrences(of: "Center", with: "Ctr")
    }
    
    private func edgeText(home: Double, away: Double, homeCode: String, awayCode: String, marginFavTeamId: Int? = nil, marginValue: Double? = nil) -> String? {
        
        if let val = marginValue {
            let h = max(0, min(1, home))
            let a = max(0, min(1, away))
            let ab = h > a ? homeCode : awayCode
            let absVal = abs(val)
            let number = absVal.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(absVal))
            : String(format: "%.1f", absVal)
            let sign = val >= 0 ? "+" : "−"
            return "\(sign)\(number) \(ab)"
        }
        
        let h = max(0, min(1, home))
        let a = max(0, min(1, away))
        let diff = abs(h - a)
        guard diff >= 0.01 else { return nil } // zobraz jen pokud rozdíl ≥ 5 p.b.
        let pts = Int((diff * 100).rounded())
        return h > a ? "+\(pts) \(homeCode)" : "+\(pts) \(awayCode)"
    }
}

// MARK: - Probability bar
struct ProbBar: View {
    let homePct: Double  // 0…1
    let awayPct: Double  // 0…1
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let home = max(0, min(1, homePct))
            let fillW = max(0, min(w, w * CGFloat(home)))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.12, green: 0.16, blue: 0.27))
                    .frame(width: fillW)
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 1)
                    .offset(x: fillW - 0.5)
                    .opacity(home > 0 && home < 1 ? 1 : 0)
            }
        }
    }
}

#Preview {
    MatchCard(gameId: 125)
}
