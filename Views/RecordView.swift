import SwiftUI

struct RecordView: View {
    let record: TeamRecord?

    var body: some View {
        if let r = record {
            Text("\(r.wins)-\(r.losses)")
                .font(.custom("Jost-SemiBold", size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 3)
        } else {
            Text("–")
                .font(.custom("Jost-SemiBold", size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 3)
        }
    }
}

