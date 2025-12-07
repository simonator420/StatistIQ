import SwiftUI

struct InfoSheet: View {
    var infoText: String
    let onDismiss: () -> Void
    
    @GestureState private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed background
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }
            
            // Bottom sheet
            VStack(spacing: 16) {
                // Drag indicator
                Rectangle()
                    .frame(width: 66, height: 3)
                    .cornerRadius(1.5)
                    .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.55))
                    .padding(.vertical, 18)
                
                // Info Text
                Text(infoText)
                    .font(.custom("Jost", size: 16).weight(.light))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 35.0)
                    .padding(.bottom, 45.0)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedCorners(radius: 16, corners: [.topLeft, .topRight]))
            //            .padding(.horizontal, 20)
            .offset(y: dragOffset > 0 ? dragOffset : 0) // follows drag
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        if value.translation.height > 80 { onDismiss() }
                    }
            )
        }
        .ignoresSafeArea()
    }
}

struct RoundedCorners: Shape {
    var radius: CGFloat = 10.0
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


#Preview {
    InfoSheet(infoText: "Hello, World!", onDismiss: {print("Dismissed")})
}
