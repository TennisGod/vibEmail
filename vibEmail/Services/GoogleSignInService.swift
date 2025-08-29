import GoogleSignIn
import UIKit

class GoogleSignInService {
    static let shared = GoogleSignInService()
    
    func signIn(completion: @escaping (Bool) -> Void) {
        print("🔄 Starting Google Sign-In")
        signInWithHint(email: nil, completion: completion)
    }
    
    func signInWithHint(email: String?, completion: @escaping (Bool) -> Void) {
        print("🔄 Starting Google Sign-In with hint: \(email ?? "none")")
        
        // Fetch clientID from Info.plist
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            completion(false)
            print("🔄 Google Sign-In failed: No clientID found")
            return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        let signInConfig = GIDConfiguration(clientID: clientID)
        let additionalScopes = ["https://www.googleapis.com/auth/gmail.modify"]
        
        // Use email hint if provided to suggest which account to use
        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController, 
            hint: email, 
            additionalScopes: additionalScopes
        ) { result, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                completion(false)
            } else if let user = result?.user {
                print("Google Sign-In success: \(user.profile?.email ?? "No email")")
                completion(true)
            } else {
                print("Google Sign-In failed: Unknown error")
                completion(false)
            }
        }
    }
}
