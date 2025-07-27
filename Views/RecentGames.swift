import SwiftUI

struct RecentGamesView: View {
    let results: [Bool] // true = win (green), false = loss (red)
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(results.indices, id: \.self) { index in
                Rectangle()
                    .fill(results[index] ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                    .cornerRadius(2)
                    .padding(.top, 7)
                    .padding(.bottom, 4)
            }
        }
    }
}
