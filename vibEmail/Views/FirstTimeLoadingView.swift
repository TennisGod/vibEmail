import SwiftUI

struct FirstTimeLoadingView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var animateGlow = false
    @State private var animateParticles = false
    @State private var showDetails = false
    
    let accountEmail: String
    
    private let loadingSteps = [
        ("Connecting to Gmail", "Establishing secure connection..."),
        ("Fetching Emails", "Downloading your email history..."),
        ("Analyzing Priority", "AI is analyzing email importance..."),
        ("Building Cache", "Optimizing for future use..."),
        ("Almost Ready", "Finalizing setup...")
    ]
    
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
            
            // Floating particles
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...6))
                        .position(
                            x: animateParticles ? CGFloat.random(in: 0...geometry.size.width) : CGFloat.random(in: 0...geometry.size.width),
                            y: animateParticles ? CGFloat.random(in: 0...geometry.size.height) : CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 3...8))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...2)),
                            value: animateParticles
                        )
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon with glow effect
                ZStack {
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: animateGlow ? 20 : 10)
                        .scaleEffect(animateGlow ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: animateGlow
                        )
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.vibPrimary)
                        .shadow(color: .vibPrimary, radius: 10)
                }
                
                // Welcome message
                VStack(spacing: 16) {
                    Text("Setting up your account")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.vibText)
                    
                    Text(accountEmail)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.vibPrimary.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Current step indicator - use real data from EmailViewModel
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(emailViewModel.setupCurrentStep.isEmpty ? "Initializing..." : emailViewModel.setupCurrentStep)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibText)
                        
                        if emailViewModel.setupCurrentStep.contains("AI") {
                            Text("This is the most time-consuming step")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.vibTextSecondary)
                                .multilineTextAlignment(.center)
                        } else if emailViewModel.setupCurrentStep.contains("Fetching") {
                            Text("Downloading your email history...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.vibTextSecondary)
                                .multilineTextAlignment(.center)
                        } else if emailViewModel.setupCurrentStep.contains("Cache") {
                            Text("Saving data for future use...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.vibTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Progress bar - use real progress from EmailViewModel
                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.vibGrayDark.opacity(0.3))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.vibPrimary,
                                        Color.vibPrimary.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: 250 * emailViewModel.setupProgress, height: 6)
                                .animation(.easeInOut(duration: 0.5), value: emailViewModel.setupProgress)
                        }
                        .frame(width: 250)
                        
                        Text("\(Int(emailViewModel.setupProgress * 100))%")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                }
                
                // First-time explanation
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetails.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Why does this take a while?")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.vibPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.vibPrimary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    if showDetails {
                        VStack(spacing: 12) {
                            explainationCard(
                                icon: "clock.fill",
                                title: "First-time setup",
                                description: "We're downloading and analyzing your emails to provide intelligent features."
                            )
                            
                            explainationCard(
                                icon: "brain.head.profile",
                                title: "AI Analysis",
                                description: "Our AI is learning your email patterns to prioritize important messages."
                            )
                            
                            explainationCard(
                                icon: "externaldrive.fill",
                                title: "Local Caching",
                                description: "We're storing processed data locally so future launches are instant."
                            )
                            
                            Text("This one-time setup won't happen again!")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.vibSuccess)
                                .padding(.top, 8)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func explainationCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.vibPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibText)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.vibSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func startAnimations() {
        animateGlow = true
        animateParticles = true
    }
}

#Preview {
    FirstTimeLoadingView(accountEmail: "user@example.com")
        .environmentObject(EmailViewModel())
} 