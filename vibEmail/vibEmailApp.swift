import SwiftUI
import GoogleSignIn

@main
struct vibEmailApp: App {
    
    init() {
        // Configure Google Sign-In on app launch
        configureGoogleSignIn()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // Force dark mode for black theme
                .accentColor(.vibPrimary) // Set accent color to brand yellow
                .onOpenURL { url in
                    // Handle Google Sign-In URL schemes
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // App became active - notify EmailViewModel
                    NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // App will resign active - notify EmailViewModel
                    NotificationCenter.default.post(name: .appWillResignActive, object: nil)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // App entered background - notify EmailViewModel
                    NotificationCenter.default.post(name: .appDidEnterBackground, object: nil)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // App will enter foreground - notify EmailViewModel
                    NotificationCenter.default.post(name: .appWillEnterForeground, object: nil)
                }
        }
    }
    
    private func configureGoogleSignIn() {
        // Get the path to GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Could not find CLIENT_ID in GoogleService-Info.plist")
            return
        }
        
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ Google Sign-In configured with client ID: \(clientId.prefix(20))...")
    }
} 