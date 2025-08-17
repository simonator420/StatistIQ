import SwiftUI

struct InteractivePopGestureModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NavigationConfigurator())
    }
}

struct NavigationConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            if let navigationController = controller.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    func enableSwipeBack() -> some View {
        self.modifier(InteractivePopGestureModifier())
    }
}
