import Foundation
import CryptoKit
import GoogleSignIn

class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}

    // Cache for profile image URLs to avoid redundant lookups
    private var imageURLCache: [String: URL?] = [:]

    /// Generate profile image URL for an email address
    /// Uses multiple fallback strategies for better coverage, matching Gmail's behavior
    func getProfileImageURL(for email: String, displayName: String? = nil) async -> URL? {
        if let cachedURL = imageURLCache[email] {
            return cachedURL
        }
        print("🖼️ Searching profile image for: \(email)")

        let domain = extractDomain(from: email)

        // Strategy 0: Google account avatar for Gmail users (current user)
        if isGoogleEmail(email), let googleURL = getGoogleAvatarURL(for: email) {
            print("✅ Found Google account avatar for: \(email)")
            imageURLCache[email] = googleURL
            return googleURL
        }

        // Strategy 1: Try Gravatar first
        if let gravatarURL = generateGravatarURL(for: email) {
            if await verifyImageExists(at: gravatarURL) {
                print("✅ Found Gravatar for: \(email)")
                imageURLCache[email] = gravatarURL
                return gravatarURL
            }
        }

        // Strategy 2: Try company logo detection for corporate emails
        if let companyLogoURL = await getCompanyLogoURL(for: email) {
            print("✅ Found company logo for: \(email)")
            imageURLCache[email] = companyLogoURL
            return companyLogoURL
        }

        // Strategy 3: Try service-specific avatars (GitHub, etc.)
        if let serviceAvatarURL = await getServiceSpecificAvatar(for: email) {
            print("✅ Found service avatar for: \(email)")
            imageURLCache[email] = serviceAvatarURL
            return serviceAvatarURL
        }

        // Strategy 4: Generate a beautiful fallback using UI Avatar service
        if let fallbackURL = generateUIAvatarURL(for: email, displayName: displayName) {
            print("✅ Generated UI Avatar for: \(email)")
            imageURLCache[email] = fallbackURL
            return fallbackURL
        }

        // No profile image found
        print("❌ No profile image found for: \(email)")
        imageURLCache[email] = nil
        return nil
    }

    // MARK: - Google Account Avatar
    /// Check if email is a Gmail address
    private func isGoogleEmail(_ email: String) -> Bool {
        let domain = extractDomain(from: email)
        return domain == "gmail.com" || domain == "googlemail.com"
    }

    /// Get the current signed-in user's Google profile image
    private func getGoogleAvatarURL(for email: String) -> URL? {
        guard let user = GIDSignIn.sharedInstance.currentUser,
              let profileEmail = user.profile?.email.lowercased(),
              profileEmail == email.lowercased(),
              let picURL = user.profile?.imageURL(withDimension: 200) else {
            return nil
        }
        return picURL
    }

    // MARK: - Gravatar
    private func generateGravatarURL(for email: String) -> URL? {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let emailData = trimmedEmail.data(using: .utf8) else { return nil }
        let hash = Insecure.MD5.hash(data: emailData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        let gravatarURLString = "https://www.gravatar.com/avatar/\(hashString)?s=200&d=404"
        return URL(string: gravatarURLString)
    }
    
    /// Get company logo URL for corporate emails
    private func getCompanyLogoURL(for email: String) async -> URL? {
        let domain = extractDomain(from: email)
        
        // Map of known company domains to their logo URLs
        let companyLogos = [
            "indeed.com": "https://logo.clearbit.com/indeed.com",
            "linkedin.com": "https://logo.clearbit.com/linkedin.com", 
            "glassdoor.com": "https://logo.clearbit.com/glassdoor.com",
            "jobleads.com": "https://logo.clearbit.com/jobleads.com",
            "thermofisher.com": "https://logo.clearbit.com/thermofisher.com",
            "nike.com": "https://logo.clearbit.com/nike.com",
            "amazon.com": "https://logo.clearbit.com/amazon.com",
            "urbanoutfitters.com": "https://logo.clearbit.com/urbanoutfitters.com",
            "google.com": "https://logo.clearbit.com/google.com",
            "gmail.com": "https://logo.clearbit.com/google.com",
            "apple.com": "https://logo.clearbit.com/apple.com",
            "microsoft.com": "https://logo.clearbit.com/microsoft.com",
            "facebook.com": "https://logo.clearbit.com/facebook.com",
            "meta.com": "https://logo.clearbit.com/meta.com",
            "twitter.com": "https://logo.clearbit.com/twitter.com",
            "github.com": "https://logo.clearbit.com/github.com",
            "stackoverflow.com": "https://logo.clearbit.com/stackoverflow.com"
        ]
        
        // Try exact domain match first
        if let logoURL = companyLogos[domain] {
            if let url = URL(string: logoURL), await verifyImageExists(at: url) {
                return url
            }
        }
        
        // Try Clearbit API for unknown companies
        let clearbitURL = "https://logo.clearbit.com/\(domain)"
        if let url = URL(string: clearbitURL), await verifyImageExists(at: url) {
            return url
        }
        
        return nil
    }
    
    /// Get service-specific avatar (for developers, social platforms, etc.)
    private func getServiceSpecificAvatar(for email: String) async -> URL? {
        let domain = extractDomain(from: email)
        
        // For GitHub users, try to extract username and get GitHub avatar
        if domain == "users.noreply.github.com" {
            if let username = extractGitHubUsername(from: email) {
                let githubAvatarURL = "https://github.com/\(username).png?size=200"
                if let url = URL(string: githubAvatarURL), await verifyImageExists(at: url) {
                    return url
                }
            }
        }
        
        return nil
    }
    
    /// Generate beautiful fallback avatar using UI Avatars service
    private func generateUIAvatarURL(for email: String, displayName: String?) -> URL? {
        let name = displayName ?? extractNameFromEmail(email)
        let initials = extractInitials(from: name)
        
        // Generate a color based on email hash for consistency
        let emailHash = abs(email.hash)
        let colors = ["3B82F6", "EF4444", "10B981", "F59E0B", "8B5CF6", "06B6D4", "F97316", "84CC16"]
        let backgroundColor = colors[emailHash % colors.count]
        
        // Create UI Avatars URL with beautiful styling
        let encodedInitials = initials.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? initials
        let uiAvatarURLString = "https://ui-avatars.com/api/?name=\(encodedInitials)&size=200&background=\(backgroundColor)&color=fff&bold=true&font-size=0.6"
        
        return URL(string: uiAvatarURLString)
    }
    
    /// Extract domain from email address
    private func extractDomain(from email: String) -> String {
        let components = email.components(separatedBy: "@")
        return components.count > 1 ? components[1].lowercased() : ""
    }
    
    /// Extract name from email address
    private func extractNameFromEmail(_ email: String) -> String {
        let localPart = email.components(separatedBy: "@").first ?? ""
        return localPart.replacingOccurrences(of: ".", with: " ")
                       .replacingOccurrences(of: "_", with: " ")
                       .replacingOccurrences(of: "-", with: " ")
                       .capitalized
    }
    
    /// Extract initials from a name
    private func extractInitials(from name: String) -> String {
        let words = name.components(separatedBy: .whitespaces)
        let initials = words.compactMap { $0.first?.uppercased() }.prefix(2).joined()
        return initials.isEmpty ? "?" : initials
    }
    
    /// Extract GitHub username from GitHub noreply email
    private func extractGitHubUsername(from email: String) -> String? {
        // GitHub noreply emails are in format: username@users.noreply.github.com
        // or ID+username@users.noreply.github.com
        let localPart = email.components(separatedBy: "@").first ?? ""
        if localPart.contains("+") {
            return localPart.components(separatedBy: "+").last
        }
        return localPart
    }
    
    /// Verify if an image exists at the given URL
    private func verifyImageExists(at url: URL) async -> Bool {
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("Failed to verify image at \(url): \(error)")
        }
        return false
    }
    
    /// Clear the image cache (useful for memory management)
    func clearCache() {
        imageURLCache.removeAll()
    }
    
    /// Get cached profile image URL without network request
    func getCachedProfileImageURL(for email: String) -> URL? {
        return imageURLCache[email] ?? nil
    }
}

// Extension to make it easier to use with Email objects
extension ProfileImageService {
    func getProfileImageURL(for email: Email) async -> URL? {
        return await getProfileImageURL(for: email.senderEmail, displayName: email.sender)
    }
} 
