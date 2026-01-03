import SwiftUI

struct CustomPagingView<Content: View>: View {
    @Binding var selectedIndex: Int
    let pageCount: Int
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    
    init(selectedIndex: Binding<Int>, pageCount: Int, @ViewBuilder content: () -> Content) {
        self._selectedIndex = selectedIndex
        self.pageCount = pageCount
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                content
                    .frame(width: geometry.size.width)
            }
            .offset(x: -CGFloat(selectedIndex) * geometry.size.width + offset)
            .animation(isDragging ? nil : .easeOut(duration: 0.3), value: selectedIndex)
            .animation(isDragging ? nil : .easeOut(duration: 0.3), value: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let translation = value.translation.width
                        
                        // Block dragging right on first page
                        if selectedIndex == 0 && translation > 0 {
                            return
                        }
                        
                        // Block dragging left on last page
                        if selectedIndex == pageCount - 1 && translation < 0 {
                            return
                        }
                        
                        offset = translation
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold = geometry.size.width * 0.3
                        
                        if value.translation.width < -threshold && selectedIndex < pageCount - 1 {
                            selectedIndex += 1
                        } else if value.translation.width > threshold && selectedIndex > 0 {
                            selectedIndex -= 1
                        }
                        
                        offset = 0
                    }
            )
        }
    }
}
