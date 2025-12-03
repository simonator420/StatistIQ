import SwiftUI
import FirebaseFirestore
import Foundation
import FirebaseAuth

struct MatchDetailView: View {
    let gameId: Int
    
    @StateObject private var vm = MatchDetailViewModel()
    @ObservedObject private var teams = TeamsDirectory.shared
    @StateObject private var favs = FavoritesStore()
    @State private var homeTextWidth: CGFloat = 0
    @State private var awayTextWidth: CGFloat = 0
    
    @State private var selectedTab: String = "Summary"
    @State private var isHomeFavorite: Bool = false
    @State private var isAwayFavorite: Bool = false
    @State private var showInfoSheet = false
    @State private var infoText: String = ""
    @State private var showLoginToast = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    let logosSize: Int = 60
    
    
    var body: some View {
        let modelReady = vm.model != nil
        let teamsReady = teams.isLoaded
        let ready = modelReady && teamsReady
        ZStack {
            if ready {
                VStack(spacing: 0) {
                    // Top Section
                    ZStack(alignment: .topLeading) {
                        Color(red: 0.12, green: 0.16, blue: 0.27)
                            .ignoresSafeArea(.all, edges: .top)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Button(action: { dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .medium))
                                }
                                .padding(.leading, 16)
                                Spacer()
                            }
                            .padding(.top, 30)
                            
                            // Centered match info
                            VStack(spacing: 4) {
                                Text(vm.model?.startTime.map { $0.asTime } ?? "—")
                                Text(vm.model?.startTime.map { $0.asDayLabel } ?? "—")
                                Text(vm.model?.venue.map { "@ \($0)" } ?? "—")
                            }
                            .font(.custom("Jost", size: 15).weight(.medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, -25)
                            .padding(.bottom, 35)
                            
                            // Teams and Logos
                            ZStack(alignment: .center) {
                                // Two equal columns with a fixed middle gap reserved for the stars
                                HStack(alignment: .top) {
                                    teamBlock(
                                        teamId: vm.model?.homeId,
                                        fallback: "Home",
                                        results: vm.recentHome,
                                        isFavorite: favs.contains(vm.model?.homeId),
                                        onToggle: { if let id = vm.model?.homeId { favs.toggle(teamId: id) } },
                                        record: vm.model?.homeRecord,
                                        textWidth: $homeTextWidth
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    
                                    Spacer().frame(width: 90) // reserve space between the teams for the stars
                                    
                                    teamBlock(
                                        teamId: vm.model?.awayId,
                                        fallback: "Away",
                                        results: vm.recentAway,
                                        isFavorite: favs.contains(vm.model?.awayId),
                                        onToggle: { if let id = vm.model?.awayId { favs.toggle(teamId: id) } },
                                        record: vm.model?.awayRecord,
                                        textWidth: $awayTextWidth
                                    )
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                
                                // Stars centered horizontally & vertically (no bottom padding hacks)
                                HStack(spacing: 60) {
                                    Button {
                                        if Auth.auth().currentUser == nil {
                                            showLoginToast = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showLoginToast = false }
                                        } else if let id = vm.model?.homeId {
                                            favs.toggle(teamId: id)
                                        }
                                    } label: {
                                        Image(systemName: favs.contains(vm.model?.homeId) ? "star.fill" : "star")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                    }
                                    
                                    Button {
                                        if Auth.auth().currentUser == nil {
                                            showLoginToast = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showLoginToast = false }
                                        } else if let id = vm.model?.awayId {
                                            favs.toggle(teamId: id)
                                        }
                                    } label: {
                                        Image(systemName: favs.contains(vm.model?.awayId) ? "star.fill" : "star")
                                            .foregroundColor(.white)
                                            .font(.system(size: 18))
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 38)
                            // Tabs
                            HStack(spacing: 0) {
                                ForEach(["Summary", "Games"], id: \.self) { tab in
                                    Button { selectedTab = tab } label: {
                                        VStack(spacing: 4) {
                                            Text(tab)
                                                .font(.custom("Jost-SemiBold", size: 15))
                                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                            Rectangle()
                                                .fill(selectedTab == tab ? Color.white : Color(red: 0.12, green: 0.16, blue: 0.27))
                                                .frame(height: 6)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                            .zIndex(2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 345.3)
                    
                    // Content
                    MatchDetailContentView(
                        vm: vm,
                        teams: teams,
                        selectedTab: $selectedTab,
                        showInfoSheet: $showInfoSheet,
                        infoText: $infoText,
                    )
                }
                .overlay(
                    ZStack {
                        if showInfoSheet {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                                .transition(.opacity)
                                .onTapGesture { showInfoSheet = false }
                            
                            InfoSheet(infoText: infoText) { showInfoSheet = false }
                                .transition(.move(edge: .bottom))
                                .zIndex(2)
                        }
                        
                        if showLoginToast {
                            VStack {
                                Spacer()
                                Text("You need to be logged in to add favorite teams.")
                                    .font(.custom("Jost", size: 15).weight(.medium))
                                    .padding()
                                    .background(Color.black.opacity(0.75))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                Spacer().frame(height: UIScreen.main.bounds.height * 0.35)
                            }
                            .transition(.opacity)
                        }
                    }
                        .animation(.easeInOut(duration: 0.3), value: showInfoSheet)
                )
                .background(colorScheme == .light ? Color.white.ignoresSafeArea() : Color.black.ignoresSafeArea())
                .navigationBarBackButtonHidden(true)
                .enableSwipeBack()
            }
            else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                    .scaleEffect(1.6)
            }
        }
        //        .animation(.easeInOut(duration: 0.3), value: ready)
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .onAppear {
            teams.loadIfNeeded()
            vm.bind(gameId: gameId)
            favs.start()
        }
        .onDisappear {
            vm.stop()
            favs.stop()
        }
    }
    
    @ViewBuilder
    private func teamBlock(teamId: Int?, fallback: String, results: [Bool], isFavorite: Bool, onToggle: @escaping () -> Void, record: TeamRecord?, textWidth: Binding<CGFloat>) -> some View {
        let t = teamId.flatMap { teams.team($0) }
        let myPrimary = teamId.flatMap { teams.team($0)?.primaryColor }
        let mySecondary = teamId.flatMap { teams.team($0)?.secondaryColor }

        let opponentId = (teamId == vm.model?.homeId)
            ? vm.model?.awayId
            : vm.model?.homeId

        let opponentPrimary = opponentId.flatMap { teams.team($0)?.primaryColor }

        let chosenColor = pickTeamColor(
            primary: myPrimary,
            secondary: mySecondary,
            opponentPrimary: opponentPrimary
        )
        
        VStack(spacing: 1) {
            //            if let id = teamId, let image = UIImage(named: "\(id)") {
            //                Image(uiImage: image).resizable().frame(width: 70, height: 70)
            //            } else {
            //                Image(systemName: "shield.lefthalf.filled").resizable().frame(width: 90, height: 90)
            //            }
            
            VStack(spacing: -8) {
                Rectangle()
                    .fill(chosenColor)
                    .frame(width: textWidth.wrappedValue, height: 4)
                
                if let id = teamId, let abbrev = teams.team(id)?.code {
                    Text(abbrev)
                        .font(.custom("Jost-Bold", size: 34))
                        .foregroundColor(.white)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: WidthPreferenceKey.self, value: geo.size.width)
                            }
                        )
                        .onPreferenceChange(WidthPreferenceKey.self) { value in
                            textWidth.wrappedValue = value
                        }
                        .frame(height: 70)
                }
            }
            
            Text(t?.name ?? fallback)
                .font(.custom("Jost-SemiBold", size: 15))
                .foregroundColor(.white)
                .padding(.top, 5)
            
            // NEW — record inline, without extra view
            if let r = record {
                Text("\(r.wins)-\(r.losses)")
                    .font(.custom("Jost-SemiBold", size: 15))
                    .foregroundColor(.white.opacity(0.9))
                //                    .padding(.top, 2)
            } else {
                Text("–")
                    .font(.custom("Jost-SemiBold", size: 15))
                    .foregroundColor(.white.opacity(0.5))
                //                    .padding(.top, 2)
            }
            
            
        }
        .multilineTextAlignment(.center)
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
        .padding(.top, 25.0)
    }
}

extension Date {
    var asTime: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.timeStyle = .short      // e.g., "18:00" or "6:00 PM"
        f.dateStyle = .none
        return f.string(from: self)
    }
    
    var asDayLabel: String {
        let cal = Calendar.autoupdatingCurrent
        if cal.isDateInToday(self) { return "Today" }
        if cal.isDateInTomorrow(self) { return "Tomorrow" }
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.timeZone = .autoupdatingCurrent
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }
}

struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension Color {
    init?(hex: String?) {
        guard let hex = hex else { return nil }
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self = Color(red: r, green: g, blue: b)
    }
}

struct RGBColor {
    let r: Double
    let g: Double
    let b: Double
}

func rgb(fromHex hex: String?) -> RGBColor? {
    guard let hex else { return nil }
    let hexSanitized = hex.replacingOccurrences(of: "#", with: "")

    var int: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&int)

    return RGBColor(
        r: Double((int >> 16) & 0xFF) / 255,
        g: Double((int >> 8) & 0xFF) / 255,
        b: Double(int & 0xFF) / 255
    )
}

func isDarkColor(_ rgb: RGBColor?) -> Bool {
    guard let rgb else { return false }

    // Determine if it is blue or purple family
    let isBlue = rgb.b > rgb.r && rgb.b > rgb.g           // blue-dominant
    let isPurple = rgb.b > 0.35 && rgb.r > 0.25           // purple-ish
    let isBlack = rgb.r < 0.10 && rgb.g < 0.10 && rgb.b < 0.10
    if isBlack {
        return true
    }

    if !(isBlue || isPurple) {
        return false
    }

    let luminance = 0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b
    let maxVal = max(rgb.r, rgb.g, rgb.b)
    let minVal = min(rgb.r, rgb.g, rgb.b)
    let saturation = maxVal - minVal

    if luminance < 0.25 { return true }

    if luminance < 0.38 && saturation < 0.50 {
        return true
    }
    return false
}



func isSimilar(_ a: RGBColor?, _ b: RGBColor?) -> Bool {
    guard let a, let b else { return false }
    let dist = sqrt(pow(a.r - b.r, 2) + pow(a.g - b.g, 2) + pow(a.b - b.b, 2))
    return dist < 0.25    // threshold tuned to avoid too similar colors
}

func pickTeamColor(
    primary: String?,
    secondary: String?,
    opponentPrimary: String?
) -> Color {
    let rgbPrimary = rgb(fromHex: primary)
    let rgbOpponent = rgb(fromHex: opponentPrimary)

    if isDarkColor(rgbPrimary) {
        if let sec = Color(hex: secondary) { return sec }
    }

    //Avoid primaries too similar to opponent
    if isSimilar(rgbPrimary, rgbOpponent) {
        if let sec = Color(hex: secondary) { return sec }
    }

    return Color(hex: primary) ?? .white
}


#Preview {
    MatchDetailView(gameId:316)
}
