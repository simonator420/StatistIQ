import SwiftUI
import FirebaseCore
import GoogleSignIn
import FBSDKCoreKit

// AppDelegate to configure Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Add Facebook SDK initialization
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        return true
    }
    
    // Handle the redirect URL from Google Sign-In
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Handle Facebook URL first
        if ApplicationDelegate.shared.application(app, open: url, options: options) {
            return true
        }
        
        // Then handle Google Sign-In URL
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct StatistIQApp: App {
    // Register AppDelegate for Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            // Use Homepage as entry point
            NavigationStack {
                Homepage()
            }
        }
    }
}
