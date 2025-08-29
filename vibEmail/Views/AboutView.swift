import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animateContent = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color.vibBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // App Icon and Header
                        headerSection
                        
                        // App Description
                        descriptionSection
                        
                        // Version Info
                        versionSection
                        
                        // Features
                        featuresSection
                        
                        // Credits
                        creditsSection
                        
                        // Links
                        linksSection
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vibPrimary)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // App Icon
            Image("AppIconNoText")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.6), value: animateContent)
            
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("vibEm")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.vibText)
                    
                    Text("ai")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.vibPrimary)
                    
                    Text("l")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.vibText)
                }
                
                Text("AI-Powered Email Experience")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vibTextSecondary)
            }
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About vibEmail")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.vibText)
            
            Text("vibEmail revolutionizes your email experience with AI-powered features, smart filtering, and intuitive design. Manage multiple Gmail accounts, create custom filters with voice commands, and enjoy text-to-speech capabilities for a truly modern email experience.")
                .font(.system(size: 15))
                .foregroundColor(.vibTextSecondary)
                .lineSpacing(4)
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
    }
    
    private var versionSection: some View {
        VStack(spacing: 16) {
            InfoRow(
                icon: "app.badge",
                title: "Version",
                value: "\(appVersion) (\(buildNumber))"
            )
            
            InfoRow(
                icon: "iphone",
                title: "Compatibility",
                value: "iOS 17.0+"
            )
            
            InfoRow(
                icon: "calendar",
                title: "Release Date",
                value: "January 2025"
            )
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(0.6), value: animateContent)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Features")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.vibText)
            
            VStack(spacing: 12) {
                AboutFeatureRow(
                    icon: "brain.head.profile",
                    title: "AI-Powered Intelligence",
                    description: "Smart email analysis, priority detection, and automated responses"
                )
                
                AboutFeatureRow(
                    icon: "person.2.circle",
                    title: "Multi-Account Support",
                    description: "Seamlessly manage multiple Gmail accounts with easy switching"
                )
                
                AboutFeatureRow(
                    icon: "line.3.horizontal.decrease.circle",
                    title: "Smart Filtering",
                    description: "Create custom filters with voice commands and AI assistance"
                )
                
                AboutFeatureRow(
                    icon: "speaker.wave.3",
                    title: "Text-to-Speech",
                    description: "Listen to your emails with adjustable playback speed"
                )
                
                AboutFeatureRow(
                    icon: "mic.circle",
                    title: "Voice Commands",
                    description: "Use speech recognition for hands-free email management"
                )
                
                AboutFeatureRow(
                    icon: "paintbrush",
                    title: "Modern Design",
                    description: "Beautiful, intuitive interface with smooth animations"
                )
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(0.8), value: animateContent)
    }
    
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Credits")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.vibText)
            
            VStack(spacing: 12) {
                CreditRow(
                    title: "Development",
                    value: "Bryan Sun"
                )
                
                CreditRow(
                    title: "AI Technology",
                    value: "OpenAI GPT-4"
                )
                
                CreditRow(
                    title: "Email Integration",
                    value: "Gmail API"
                )
                
                CreditRow(
                    title: "Authentication",
                    value: "Google Sign-In SDK"
                )
                
                CreditRow(
                    title: "Speech Technology",
                    value: "Apple Speech Framework"
                )
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(1.0), value: animateContent)
    }
    
    private var linksSection: some View {
        VStack(spacing: 16) {
            LinkButton(
                icon: "shield.checkered",
                title: "Privacy Policy",
                action: { openPrivacyPolicy() }
            )
            
            LinkButton(
                icon: "doc.text",
                title: "Terms of Service",
                action: { openTermsOfService() }
            )
            
            LinkButton(
                icon: "heart",
                title: "Rate vibEmail",
                action: { openAppStoreRating() }
            )
            
            LinkButton(
                icon: "square.and.arrow.up",
                title: "Share vibEmail",
                action: { shareApp() }
            )
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(1.2), value: animateContent)
    }
    
    // MARK: - Actions
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://vibemail.app/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://vibemail.app/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppStoreRating() {
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareApp() {
        let shareText = "Check out vibEmail - AI-powered email experience! https://apps.apple.com/app/id123456789"
        let activityController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.vibPrimary)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.vibText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.vibTextSecondary)
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.vibPrimary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.vibText)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.vibTextSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

struct CreditRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.vibText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.vibTextSecondary)
        }
    }
}

struct LinkButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.vibPrimary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.vibText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.vibTextSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.vibSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vibTextSecondary.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AboutView()
} 