import SwiftUI
import GoogleSignIn

struct ManageAccountsView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddAccount = false
    @State private var animateHeader = false
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.vibBlack,
                    Color.vibGrayDark.opacity(0.6),
                    Color.vibBlack
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle floating particles
            GeometryReader { geometry in
                ForEach(0..<10, id: \.self) { index in
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.04))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 4...10))
                                .repeatForever(autoreverses: true),
                            value: animateHeader
                        )
                }
            }
            
            VStack(spacing: 0) {
                // Header with glass morphism effect
                headerView
                
                // Account list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Show current account first, then others
                        ForEach(Array(sortedAccounts.enumerated()), id: \.element.id) { index, account in
                            AccountRowView(
                                account: account, 
                                isCurrentAccount: account.id == emailViewModel.currentAccount?.id
                            ) {
                                // Remove account action
                                if emailViewModel.accounts.count > 1 {
                                    emailViewModel.removeAccount(account)
                                }
                            }
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 30)
                            .animation(.easeIn(duration: 0.8).delay(Double(index) * 0.1), value: animateContent)
                            .onTapGesture {
                                if account.id != emailViewModel.currentAccount?.id {
                                    // Add haptic feedback for account switching
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    // Switch account
                                    emailViewModel.setCurrentAccount(account)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Add account button with modern styling
                Button(action: {
                    showingAddAccount = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Account")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.vibBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .vibPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                    .overlay(
                        Capsule()
                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .opacity(animateButton ? 1.0 : 0.0)
                .offset(y: animateButton ? 0 : 20)
                .animation(.easeIn(duration: 0.8).delay(0.6), value: animateButton)
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
                    .environmentObject(emailViewModel)
            }
            .onAppear {
                // Start animations
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateHeader = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        animateContent = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        animateButton = true
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var sortedAccounts: [EmailAccount] {
        let currentAccount = emailViewModel.currentAccount
        let otherAccounts = emailViewModel.accounts.filter { $0.id != currentAccount?.id }
        
        if let current = currentAccount {
            return [current] + otherAccounts
        } else {
            return emailViewModel.accounts
        }
    }
    
    private var headerView: some View {
        HStack {
            // Done button with modern styling
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.vibPrimary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            // Title with modern styling
            Text("Manage Accounts")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.vibText)
            
            Spacer()
            
            // Invisible button for balance
            Button(action: {}) {
                Text("Done")
                    .foregroundColor(.clear)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.vibSurface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .offset(y: animateHeader ? 0 : -20)
        .opacity(animateHeader ? 1.0 : 0.0)
    }
}

struct AccountRowView: View {
    let account: EmailAccount
    let isCurrentAccount: Bool
    let onRemove: () -> Void
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var animateRow = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image or initial with modern styling
            ZStack {
                // Glow effect for current account
                if isCurrentAccount {
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.3))
                        .frame(width: 58, height: 58)
                        .blur(radius: 8)
                        .scaleEffect(animateRow ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateRow)
                }
                
                if let url = account.profileImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.vibPrimary.opacity(0.2))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 2)
                    )
                } else {
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.2))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(String(account.displayName.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.vibPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(account.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibText)
                    
                    if isCurrentAccount {
                        Text("(Current)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.vibPrimary.opacity(0.15))
                            )
                    } else {
                        Text("Tap to switch")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.vibTextSecondary.opacity(0.1))
                            )
                    }
                }
                
                Text(account.email)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.caption)
                        .foregroundColor(.vibPrimary)
                    Text(account.provider)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                }
            }
            
            Spacer()
            
            // Remove button with modern styling
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(emailViewModel.accounts.count > 1 ? .vibError : .vibGrayMedium)
                    .font(.system(size: 16, weight: .medium))
                    .padding(10)
                    .background(
                        Circle()
                            .fill(emailViewModel.accounts.count > 1 ? Color.vibError.opacity(0.1) : Color.vibGrayMedium.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(emailViewModel.accounts.count <= 1)
            .opacity(emailViewModel.accounts.count > 1 ? 1.0 : 0.4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vibSurface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isCurrentAccount ? Color.vibPrimary.opacity(0.3) : Color.vibPrimary.opacity(0.1),
                            lineWidth: isCurrentAccount ? 2 : 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animateRow = true
            }
        }
    }
}

struct AddAccountView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedProvider = "Gmail"
    @State private var isLoading = false
    @State private var showError = false
    @State private var animateContent = false
    
    let providers = ["Gmail", "Outlook", "Yahoo", "iCloud"]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.vibBlack,
                    Color.vibGrayDark.opacity(0.6),
                    Color.vibBlack
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle floating particles
            GeometryReader { geometry in
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.04))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 4...10))
                                .repeatForever(autoreverses: true),
                            value: animateContent
                        )
                }
            }
            
            VStack(spacing: 0) {
                // Header with glass morphism effect
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Back")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.vibPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.vibPrimary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    Text("Add Account")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.vibText)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button(action: {}) {
                        Text("Back")
                            .foregroundColor(.clear)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.vibSurface.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Header section
                    VStack(spacing: 12) {
                        Text("Connect Another Account")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.vibText)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeIn(duration: 0.8).delay(0.1), value: animateContent)
                        
                        Text("Add a new email account to manage multiple inboxes")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeIn(duration: 0.8).delay(0.2), value: animateContent)
                    }
                    
                    // Provider selection with modern styling
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select email provider:")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibText)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeIn(duration: 0.8).delay(0.3), value: animateContent)
                        
                        // Provider picker with custom styling
                        Menu {
                            ForEach(providers, id: \.self) { provider in
                                Button(action: {
                                    selectedProvider = provider
                                }) {
                                    HStack {
                                        Image(systemName: "envelope.circle.fill")
                                            .foregroundColor(.vibPrimary)
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
                                Image(systemName: "envelope.circle.fill")
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
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeIn(duration: 0.8).delay(0.4), value: animateContent)
                    }
                    
                    // Connect button with modern styling
                    Button(action: {
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
                                        }
                                        presentationMode.wrappedValue.dismiss()
                                    } else {
                                        showError = true
                                    }
                                }
                            }
                        } else {
                            // Handle other providers
                            isLoading = false
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
                        .foregroundColor(.vibBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .vibPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                        .overlay(
                            Capsule()
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(isLoading)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeIn(duration: 0.8).delay(0.5), value: animateContent)
                    
                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Connection Failed"),
                    message: Text("Unable to connect to \(selectedProvider). Please try again."),
                    dismissButton: .default(Text("Try Again"))
                )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateContent = true
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ManageAccountsView()
        .environmentObject(EmailViewModel())
} 