import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Binding var isShowing: Bool
    @Binding var showingHelp: Bool
    @Binding var showingFeedback: Bool
    @Binding var showingAbout: Bool
    @State private var animateMenu = false
    @State private var animateItems = false
    
    var body: some View {
        ZStack {
            // Background overlay with blur effect
            if isShowing {
                Color.vibBlack.opacity(0.4)
                    .ignoresSafeArea()
                    .blur(radius: 0.5)
                    .onTapGesture {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
            }
            
            // Side menu with glass morphism effect
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with modern styling
                    headerView
                    
                    // Menu items
                    ScrollView {
                        VStack(spacing: 24) {
                            // Support section
                            supportSection
                        }
                        .padding(.vertical, 24)
                    }
                    
                    Spacer()
                }
                .frame(width: 300)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.vibSurface.opacity(0.95),
                            Color.vibSurface.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 10, y: 0)
                .offset(x: isShowing ? 0 : -300)
                .animation(.easeInOut(duration: 0.4), value: isShowing)
                .onAppear {
                    if isShowing {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            animateMenu = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                animateItems = true
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                // vibEmail Logo with glow effect
                ZStack {
                    // Glow effect
                    Image("AppIconNoText")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .blur(radius: 8)
                        .opacity(0.3)
                        .scaleEffect(animateMenu ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8), value: animateMenu)
                    
                Image("AppIconNoText")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .scaleEffect(animateMenu ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.6), value: animateMenu)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        Text("vibEm")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.vibText)
                        
                        Text("ai")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.vibPrimary)
                            .scaleEffect(animateMenu ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: animateMenu)
                        
                        Text("l")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.vibText)
                    }
                    
                    Text("AI-Powered Email")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                }
                
                Spacer()
                
                // Close button with modern styling
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.vibTextSecondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.vibSurface.opacity(0.5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Current account info
            if let currentAccount = emailViewModel.currentAccount {
                HStack(spacing: 12) {
                    if let url = currentAccount.profileImageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle().fill(Color.vibPrimary.opacity(0.2))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 2)
                        )
                    } else {
                Circle()
                    .fill(Color.vibPrimary.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                                Text(String(currentAccount.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.vibPrimary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 2)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentAccount.displayName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibText)
                        
                        Text(currentAccount.email)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Online indicator
                    Circle()
                        .fill(Color.vibSuccess)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.vibSuccess.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.vibPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                        )
                )
                .opacity(animateMenu ? 1.0 : 0.0)
                .offset(y: animateMenu ? 0 : 20)
                .animation(.easeIn(duration: 0.8).delay(0.3), value: animateMenu)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.vibSurface.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(animateMenu ? 1.0 : 0.0)
        .offset(y: animateMenu ? 0 : -20)
        .animation(.easeIn(duration: 0.8), value: animateMenu)
    }
    

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vibPrimary)
                Text("Support")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                MenuItemView(
                    icon: "book",
                    title: "Help Center",
                    subtitle: "FAQs and tutorials",
                    animateItems: animateItems,
                    delay: 0.1
                ) {
                    closeMenuAndShow { showingHelp = true }
                }
                
                MenuItemView(
                    icon: "message",
                    title: "Send Feedback",
                    subtitle: "Report issues or suggestions",
                    animateItems: animateItems,
                    delay: 0.2
                ) {
                    closeMenuAndShow { showingFeedback = true }
                }
                
                MenuItemView(
                    icon: "info.circle",
                    title: "About vibEmail",
                    subtitle: "Version and app info",
                    animateItems: animateItems,
                    delay: 0.3
                ) {
                    closeMenuAndShow { showingAbout = true }
                }
            }
        }
    }
    

    
    private func closeMenuAndShow(action: @escaping () -> Void) {
        // Close menu with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Execute action immediately for sheet presentation
        action()
        
        // Close menu after action
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    let subtitle: String
    let animateItems: Bool
    let delay: Double
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Visual feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Execute action
            action()
            
            // Reset press state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 16) {
                // Icon with modern styling
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.vibPrimary)
                    .frame(width: 28, height: 28)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.vibPrimary.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibText)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.vibTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateItems ? 1.0 : 0.0)
        .offset(x: animateItems ? 0 : -30)
        .animation(.easeIn(duration: 0.6).delay(delay), value: animateItems)
    }
}

#Preview {
    SideMenuView(
        isShowing: .constant(true),
        showingHelp: .constant(false),
        showingFeedback: .constant(false),
        showingAbout: .constant(false)
    )
    .environmentObject(EmailViewModel())
} 
