import SwiftUI

enum SpotlightRegion {
    case full
    case header
    case teams
    case margin
    case probBar
    case probText
    
    func frame(in cardHeight: CGFloat) -> CGRect {
        let cardWidth: CGFloat = 380
        switch self {
        case .full:
            return CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight)
        case .header:
            return CGRect(x: 60, y: 9, width: 255, height: 30)
        case .teams:
            return CGRect(x: 6, y: 50, width: 191, height: 60)
        case .margin:
            return CGRect(x: 285, y: 55, width: 88, height: 50)
        case .probBar:
            return CGRect(x: 5, y: 112, width: 371, height: 19)
        case .probText:
            return CGRect(x: 8, y: 131, width: cardWidth - 15, height: 22)
        }
    }
}

struct SpotlightOverlay: View {
    let region: SpotlightRegion
    let cardHeight: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            let spotlightFrame = region.frame(in: cardHeight)
            
            ZStack {
                // Full dimming overlay
                Color.black.opacity(0.7)
                
                // Clear cutout for the spotlight region
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: spotlightFrame.width, height: spotlightFrame.height)
                    .position(x: spotlightFrame.midX, y: spotlightFrame.midY)
                    .blendMode(.destinationOut)
                
            }
            .compositingGroup()
            .padding(.vertical, 0.1)
        }
    }
}

struct MatchCardDummy: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack(spacing: 10) {
            // HEADER
            HStack(spacing: 6) {
                Text("7:30 PM")
                    .font(.custom("Jost", size: 13))
                    .foregroundColor(.secondary)

                Text("·")
                    .font(.custom("Jost", size: 13))
                    .foregroundColor(.secondary)

                Text("Chase Center, San Francisco")
                    .font(.custom("Jost", size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Divider().opacity(0.12).padding(.horizontal, 16)

            // TEAMS
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TeamHalfColorDot (primary: Color(red: 29/255, green: 66/255, blue: 138/255), secondary: Color(red: 255/255, green: 199/255, blue: 44/255), size: 10)
                        Text("Golden State Warriors")
                            .font(.custom("Jost", size: 16).weight(.medium)
                            )
                    }
                    HStack {
                        TeamHalfColorDot (primary: Color(red: 85/255, green: 37/255, blue: 130/255), secondary: Color(red: 249/255, green: 160/255, blue: 27/255), size: 10)
                        Text("Los Angeles Lakers")
                            .font(.custom("Jost", size: 16).weight(.medium)
                        )
                    }
                }

                Spacer()

                Text("+4 GSW")
                    .font(.custom("Jost", size: 13))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 1)

            // PROBABILITY BAR + TEXT
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 10)
                    .overlay(
                        GeometryReader { geo in
                            let fillW = geo.size.width * 0.64
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(red: 0.12, green: 0.16, blue: 0.27))
                                .frame(width: geo.size.width * 0.64)
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 1)
                                .offset(x: fillW - 0.5)
                        }
                        
                    )
                    .clipShape(Capsule())
                    .padding(.horizontal, 0)

                HStack {
                    Text("GSW 64%")
                        .font(.custom("Jost", size: 12))
                    Spacer()
                    Text("36% LAL")
                        .font(.custom("Jost", size: 12))
                }
                .padding(.horizontal, 0)
            }
        }
        .frame(height: 165)
        .padding(.horizontal, 12)
        .background(
            colorScheme == .light
            ? Color.white
            : Color(.systemGray6)
        )
        .cornerRadius(14)
        .shadow(radius: 8)
    }
}

struct OnboardingSlide {
    let title: String
    let text: String
    let spotlight: SpotlightRegion
}

struct MatchCardOnboardingView: View {
    let dismiss: () -> Void
    @State private var index: Int = 0

    let slides: [OnboardingSlide] = [
        .init(title: "Match Card Overview",
              text: "Swipe to explore each part of the match card.",
              spotlight: .full),

        .init(title: "Game Info",
              text: "Shows the game time and venue location.",
              spotlight: .header),

        .init(title: "Team Matchup",
              text: "Displays both teams with their color indicators.",
              spotlight: .teams),

        .init(title: "Expected Margin",
              text: "Indicates the projected point difference between teams.",
              spotlight: .margin),
        
        .init(title: "Win Percentages",
              text: "Shows the predicted chance of each team winning.",
              spotlight: .probText),

        .init(title: "Win Probability Bar",
              text: "Visual representation of each team's win chance.",
              spotlight: .probBar),
    ]

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.16, blue: 0.27)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack {
                Spacer(minLength: 40)

                // ------------- SLIDES -------------
                TabView(selection: $index) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                        VStack(spacing: 20) {
                            Text(slide.title)
                                .font(.custom("Jost", size: 22).weight(.semibold))
                                .foregroundColor(.white)

                            // Match card with spotlight overlay
                            ZStack {
                                MatchCardDummy()
                                    .frame(maxWidth: 380)
                                
                                SpotlightOverlay(region: slide.spotlight, cardHeight: 165)
                                    .frame(width: 380, height: 165)
                                    .cornerRadius(14)
                                    .allowsHitTesting(false)
                            }
                            .padding(.top, 8)

                            Text(slide.text)
                                .font(.custom("Jost", size: 16))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)

                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle())

                // ------------- BUTTONS -------------
                HStack(spacing: 12) {

                    if index < slides.count - 1 {

                        // Skip only when not last
                        Button(action: dismiss) {
                            Text("Skip")
                                .font(.custom("Jost", size: 17).weight(.medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                                )
                        }

                        // Next
                        Button {
                            let next = index + 1

                            if next == slides.count - 1 {
                                // ❌ no animation when going to last slide
                                index = next
                            } else {
                                // ✅ animated for all others
                                withAnimation {
                                    index = next
                                }
                            }
                        } label: {
                            Text("Next")
                                .font(.custom("Jost", size: 17).weight(.medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                                )
                        }

                    } else {
                        // Last slide -> Done
                        Button(action: dismiss) {
                            Text("Done")
                                .font(.custom("Jost", size: 17).weight(.medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                                )
                        }
                    }
                }
                
                Spacer().frame(height: 40)
            }
        }
    }
}

#if DEBUG
struct MatchCardOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.12, green: 0.16, blue: 0.27)
                .ignoresSafeArea()

            MatchCardOnboardingView {
                print("Dismissed onboarding")
            }
        }
        .previewDisplayName("Onboarding Overlay Preview")
    }
}
#endif
