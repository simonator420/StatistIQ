import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.16, blue: 0.27)
                .ignoresSafeArea()
            
            Text("StatistIQ")
                .font(.custom("Jost-SemiBold", size: 68))
                .fontWeight(.bold)
                .foregroundColor(.white)
//                .padding(.bottom, 70)
        }
        .onAppear {
            // Delay before navigating to Homepage
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            Homepage()
        }
    }
}

#Preview {
    SplashView()
}
