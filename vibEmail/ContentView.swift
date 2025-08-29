import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @StateObject private var emailViewModel = EmailViewModel()
    @State private var isAuthenticated = false
    @State private var showingLogin = true
    
    var body: some View {
        Group {
            if isAuthenticated {
                if emailViewModel.showingFirstTimeLoading {
                    FirstTimeLoadingView(accountEmail: emailViewModel.currentAccount?.email ?? "Loading...")
                        .environmentObject(emailViewModel)
                } else {
                    EmailListView()
                        .environmentObject(emailViewModel)
                }
            } else {
                LoginView(isAuthenticated: $isAuthenticated, emailViewModel: emailViewModel)
            }
        }
        .onReceive(emailViewModel.$accounts) { accounts in
            // Automatically authenticate if we have persisted accounts
            if !accounts.isEmpty && !isAuthenticated {
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    print("🔐 Auto-authenticated with persisted accounts")
                }
            } else if accounts.isEmpty && isAuthenticated {
                // If accounts were cleared (due to invalid session), go back to login
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    print("🔓 Logged out due to invalid session")
                }
            }
        }
        .onReceive(emailViewModel.$currentAccount) { currentAccount in
            // Load emails when current account is set
            if currentAccount != nil && isAuthenticated {
                Task {
                    await emailViewModel.loadRealEmails()
                }
            }
        }
    }
}

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @ObservedObject var emailViewModel: EmailViewModel
    @State private var selectedProvider = "Gmail"
    @State private var isLoading = false
    @State private var showError = false
    @State private var animateLogo = false
    @State private var animateContent = false
    @State private var animateButton = false
    
    let providers = ["Gmail"]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.vibBlack,
                    Color.vibGrayDark.opacity(0.8),
                    Color.vibBlack
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles effect
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...6))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 3...8))
                                .repeatForever(autoreverses: true),
                            value: animateLogo
                        )
                }
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main content container
                VStack(spacing: 40) {
                    // Logo and branding section
                    VStack(spacing: 25) {
                        // Animated logo
                        ZStack {
                            // Glow effect
                            Circle()
                                .fill(Color.vibPrimary.opacity(0.2))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                                .scaleEffect(animateLogo ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateLogo)
                            
                            // Main logo
                            Image("AppIconNoText")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateLogo ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateLogo)
                        }
                        
                        // App title with animated text
                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Text("vibEm")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.vibText)
                                
                                Text("ai")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.vibPrimary)
                                    .scaleEffect(animateLogo ? 1.1 : 1.0)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateLogo)
                                
                                Text("l")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.vibText)
                            }
                            
                            Text("AI-Powered Email Management")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.vibTextSecondary)
                                .opacity(animateContent ? 1.0 : 0.0)
                                .animation(.easeIn(duration: 0.8).delay(0.3), value: animateContent)
                        }
                    }
                    .offset(y: animateContent ? 0 : -50)
                    .animation(.easeOut(duration: 0.8), value: animateContent)
                    
                    // Feature highlights
                    VStack(spacing: 16) {
                        FeatureRow(icon: "brain.head.profile", text: "AI-powered email analysis", animateContent: animateContent, delay: 0.4)
                        FeatureRow(icon: "star.circle.fill", text: "Smart priority detection", animateContent: animateContent, delay: 0.5)
                        FeatureRow(icon: "bolt.circle.fill", text: "Lightning-fast responses", animateContent: animateContent, delay: 0.6)
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.8).delay(0.4), value: animateContent)
                    
                    // Provider selection
                    VStack(spacing: 16) {
                        Text("Connect your email")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibText)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 0.8).delay(0.7), value: animateContent)
                        
                        // Provider picker with custom styling
                        Menu {
                            ForEach(providers, id: \.self) { provider in
                                Button(action: {
                                    selectedProvider = provider
                                }) {
                                    HStack {
                                        Text(provider)
                                        if selectedProvider == provider {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.vibPrimary)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: providerIcon(for: selectedProvider))
                                    .foregroundColor(.vibPrimary)
                                    .font(.title2)
                                
                                Text(selectedProvider)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.vibText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.vibTextSecondary)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.vibSurface.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(0.8), value: animateContent)
                    }
                    
                    // Connect button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            animateButton = true
                        }
                        
                        isLoading = true
                        if selectedProvider == "Gmail" {
                            GoogleSignInService.shared.signIn { success in
                                DispatchQueue.main.async {
                                    isLoading = false
                                    if success {
                                        if let user = GIDSignIn.sharedInstance.currentUser {
                                            let account = EmailAccount(
                                                email: user.profile?.email ?? "",
                                                provider: "Gmail",
                                                displayName: user.profile?.name ?? "",
                                                isActive: true,
                                                lastSync: Date(),
                                                profileImageURL: user.profile?.imageURL(withDimension: 80)
                                            )
                                            emailViewModel.addAccount(account)
                                            emailViewModel.setCurrentAccount(account)
                                        }
                                        isAuthenticated = true
                                    } else {
                                        showError = true
                                    }
                                }
                            }
                        } else {
                            // Handle other providers or show a message
                            isLoading = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                animateButton = false
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .vibBlack))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "link.circle.fill")
                                    .font(.title2)
                            }
                            
                            Text(isLoading ? "Connecting..." : "Connect \(selectedProvider)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.vibBlack)
                        .cornerRadius(20)
                        .shadow(color: .vibPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                        .scaleEffect(animateButton ? 0.95 : 1.0)
                    }
                    .disabled(isLoading)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.8).delay(0.9), value: animateContent)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                
                Spacer()
                
                // Footer
                VStack(spacing: 8) {
                    Text("Secure • Private • Fast")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(1.0), value: animateContent)
                    
                    Text("Powered by advanced AI technology")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(.vibTextSecondary.opacity(0.7))
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.8).delay(1.1), value: animateContent)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animateLogo = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateContent = true
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Connection Failed"),
                message: Text("Unable to connect to \(selectedProvider). Please try again."),
                dismissButton: .default(Text("Try Again"))
            )
        }
    }
    
    private func providerIcon(for provider: String) -> String {
        switch provider {
        case "Gmail": return "g.circle.fill"  // Closest to Gmail's G
        case "Outlook": return "o.circle.fill" // For Outlook
        case "Yahoo": return "y.circle.fill"   // For Yahoo
        case "iCloud": return "icloud.fill"    // Apple has this one!
        default: return "envelope.circle.fill"
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let animateContent: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.vibPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.vibTextSecondary)
            
            Spacer()
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(x: animateContent ? 0 : -20)
        .animation(.easeIn(duration: 0.6).delay(delay), value: animateContent)
    }
}

#Preview {
    ContentView()
} 
