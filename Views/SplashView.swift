import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.16, blue: 0.27)
                .ignoresSafeArea()
            
            Image("text")
                .resizable()
                .frame(width: 280, height: 82)
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
