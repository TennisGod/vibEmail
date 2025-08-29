import SwiftUI
import GoogleSignIn
import Speech

struct EmailListView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var showingCompose = false
    @State private var showingSortOptions = false
    @State private var showingAccountMenu = false
    @State private var showingEmailDetail = false
    @State private var showingManageAccounts = false
    @State private var animateHeader = false
    @State private var animateContent = false
    @State private var showingFilterSheet = false
    @State private var showingCustomFilterChat = false
    @State private var showingHelp = false
    @State private var showingFeedback = false
    @State private var showingAbout = false
    
    // Multi-select functionality
    @State private var isSelectMode = false
    @State private var selectedEmails: Set<String> = []
    @State private var showingBatchActions = false
    
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
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.05))
                        .frame(width: CGFloat.random(in: 1...4))
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
            
            NavigationView {
                VStack(spacing: 0) {
                    // Enhanced header with search and menu
                    enhancedHeaderView
                    
                    // Sort options
                    if showingSortOptions {
                        sortOptionsView
                    }
                    
                    // Email list
                    emailListView
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showingCompose) {
                    ComposeView()
                        .environmentObject(emailViewModel)
                }
                .sheet(isPresented: $showingEmailDetail) {
                    if let selectedEmail = emailViewModel.selectedEmail {
                        EmailDetailView(email: selectedEmail)
                            .environmentObject(emailViewModel)
                    }
                }
                .sheet(isPresented: $showingManageAccounts) {
                    ManageAccountsView()
                        .environmentObject(emailViewModel)
                }
                .sheet(isPresented: $showingHelp) {
                    HelpView()
                        .environmentObject(emailViewModel)
                }
                .sheet(isPresented: $showingFeedback) {
                    FeedbackView()
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
                .onAppear {
                    // Load real emails when view appears (after authentication)
                    if emailViewModel.emails.isEmpty {
                        Task {
                            await emailViewModel.loadRealEmails()
                        }
                    }
                    
                    // Start animations
                    withAnimation(.easeInOut(duration: 0.8)) {
                        animateHeader = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            animateContent = true
                        }
                    }
                }
            }
            
            // Side menu overlay
            if emailViewModel.showingSideMenu {
                SideMenuView(
                    isShowing: $emailViewModel.showingSideMenu,
                    showingHelp: $showingHelp,
                    showingFeedback: $showingFeedback,
                    showingAbout: $showingAbout
                )
                    .environmentObject(emailViewModel)
            }
            
            // Floating Audio Player
            VStack {
                Spacer()
                AudioPlayerView(textToSpeechService: emailViewModel.textToSpeechService)
                    .environmentObject(emailViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
            }
        }
        
        // Batch actions toolbar (appears when emails are selected)
        if isSelectMode && !selectedEmails.isEmpty {
            batchActionsToolbar
                .frame(maxWidth: .infinity, alignment: .bottom)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private var enhancedHeaderView: some View {
        VStack(spacing: 0) {
            // Main header with glass morphism effect
            HStack(spacing: 8) {
                // Hamburger menu button with modern styling
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        emailViewModel.showingSideMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.vibText)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.vibSurface.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                // Enhanced search bar
                SearchBarView(text: $emailViewModel.searchText)
                
                // Account management button
                Menu {
                    // Current account at top
                    if let currentAccount = emailViewModel.currentAccount {
                        Button(action: {}) {
                            HStack {
                                AsyncImage(url: currentAccount.profileImageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.vibPrimary.opacity(0.3))
                                        .overlay(
                                            Text(String(currentAccount.displayName.prefix(1)).uppercased())
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.vibPrimary)
                                        )
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currentAccount.displayName)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.vibText)
                                    Text(currentAccount.email)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.vibTextSecondary)
                                }
                                
                                Spacer()
                                
                                Text("(Current)")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.vibPrimary)
                            }
                        }
                        .disabled(true)
                    }
                    
                    // Other connected accounts
                    ForEach(emailViewModel.accounts.filter { $0.id != emailViewModel.currentAccount?.id }) { account in
                    Button(action: {
                            emailViewModel.setCurrentAccount(account)
                        }) {
                            HStack {
                                AsyncImage(url: account.profileImageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.vibPrimary.opacity(0.3))
                                        .overlay(
                                            Text(String(account.displayName.prefix(1)).uppercased())
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.vibPrimary)
                                        )
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.displayName)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.vibText)
                                    Text(account.email)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.vibTextSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showingManageAccounts = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vibPrimary)
                            Text("Manage Accounts")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.vibText)
                        }
                    }
                } label: {
                    AsyncImage(url: emailViewModel.currentAccount?.profileImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                            .fill(Color.vibPrimary.opacity(0.3))
                                .overlay(
                                Text(String(emailViewModel.currentAccount?.displayName.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.vibPrimary)
                            )
                    }
                    .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    .background(
                        Circle()
                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                }
                
                .sheet(isPresented: $showingFilterSheet) {
                    ZStack {
                        // Animated gradient background with floating particles
                        let backgroundGradient = LinearGradient(
                            gradient: Gradient(colors: [
                                Color.vibBlack,
                                Color.vibGrayDark.opacity(0.8),
                                Color.vibBlack
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        backgroundGradient
                            .ignoresSafeArea()
                        .overlay(
                                // Floating particles effect
                                ZStack {
                                    ForEach(0..<6, id: \.self) { index in
                            Circle()
                                            .fill(Color.vibPrimary.opacity(0.08))
                                            .frame(width: CGFloat.random(in: 6...16))
                                            .offset(
                                                x: CGFloat.random(in: -180...180),
                                                y: CGFloat.random(in: -300...300)
                                            )
                                            .animation(
                                                Animation.easeInOut(duration: Double.random(in: 4...8))
                                                    .repeatForever(autoreverses: true),
                                                value: UUID()
                                            )
                                    }
                                }
                            )
                            .background(.ultraThinMaterial)
                        
                        VStack(spacing: 0) {
                            // Modern header with enhanced styling
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Filter Emails")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(.vibText)
                                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                    Text("Customize your email view")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.vibTextSecondary)
                                }
                                Spacer()
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingFilterSheet = false
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(gradient: Gradient(colors: [Color.vibSurface.opacity(0.4), Color.vibSurface.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 44, height: 44)
                                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                                        Image(systemName: "xmark")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.vibTextSecondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.top, 32)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 20)
                            
                            // Enhanced gradient divider
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.vibPrimary.opacity(0.3), Color.clear]), startPoint: .leading, endPoint: .trailing))
                                .frame(height: 1)
                                .padding(.horizontal, 28)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    // Category Filters (Starred, Sent, Trash)
                                    ForEach(EmailCategoryFilter.allCases, id: \.self) { filter in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                emailViewModel.toggleFilter(filter)
                                            }
                                        }) {
                                            HStack(spacing: 18) {
                                                // Enhanced icon container with gradient
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: emailViewModel.activeFilters.contains(filter) ? 
                                                                    [filter.color.opacity(0.4), filter.color.opacity(0.2)] : 
                                                                    [Color.vibSurface.opacity(0.5), Color.vibSurface.opacity(0.3)]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 52, height: 52)
                                                        .shadow(color: emailViewModel.activeFilters.contains(filter) ? filter.color.opacity(0.4) : .black.opacity(0.15), radius: 10, x: 0, y: 5)
                                                    
                                                    Image(systemName: filter.icon)
                                                        .font(.system(size: 22, weight: .semibold))
                                                        .foregroundColor(emailViewModel.activeFilters.contains(filter) ? filter.color : .vibTextSecondary)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(filter.displayName)
                                                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                                                        .foregroundColor(emailViewModel.activeFilters.contains(filter) ? filter.color : .vibText)
                                                    Text(filterDescription(for: filter))
                                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                                        .foregroundColor(.vibTextSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                // Enhanced checkmark with glow effect
                                                if emailViewModel.activeFilters.contains(filter) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(filter.color)
                                                            .frame(width: 32, height: 32)
                                                            .shadow(color: filter.color.opacity(0.5), radius: 8, x: 0, y: 4)
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 16, weight: .bold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 18)
                                            .background(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: emailViewModel.activeFilters.contains(filter) ? 
                                                                [Color.vibSurface.opacity(0.3), Color.vibSurface.opacity(0.2)] : 
                                                                [Color.vibSurface.opacity(0.2), Color.vibSurface.opacity(0.1)]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .shadow(color: .black.opacity(emailViewModel.activeFilters.contains(filter) ? 0.2 : 0.1), radius: 15, x: 0, y: 8)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 22)
                                                    .stroke(
                                                        emailViewModel.activeFilters.contains(filter) ? filter.color.opacity(0.5) : Color.clear,
                                                        lineWidth: 2.5
                                                    )
                                            )
                                            .scaleEffect(emailViewModel.activeFilters.contains(filter) ? 1.02 : 1.0)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: emailViewModel.activeFilters)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    // Saved Custom Filters
                                    if !emailViewModel.savedCustomFilters.isEmpty {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Saved Custom Filters")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(.vibTextSecondary)
                                                .padding(.horizontal, 18)
                                            
                                            ForEach(emailViewModel.savedCustomFilters) { filter in
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                        if emailViewModel.activeSavedFilter?.id == filter.id {
                                                            // If this filter is already active, deselect it
                                                            emailViewModel.clearCustomFilter()
                    } else {
                                                            // Otherwise, apply this filter
                                                            emailViewModel.applyCustomFilter(filter)
                                                        }
                                                    }
                                                }) {
                                                    HStack(spacing: 18) {
                                                        // Enhanced icon container with gradient
                                                        ZStack {
                                                            RoundedRectangle(cornerRadius: 14)
                                                                                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: emailViewModel.activeSavedFilter?.id == filter.id ? 
                                                                    [Color.purple.opacity(0.4), Color.blue.opacity(0.2)] : 
                                                                    [Color.vibSurface.opacity(0.5), Color.vibSurface.opacity(0.3)]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 52, height: 52)
                                                        .shadow(color: emailViewModel.activeSavedFilter?.id == filter.id ? Color.purple.opacity(0.4) : .black.opacity(0.15), radius: 10, x: 0, y: 5)
                                                            
                                                            Image(systemName: "wand.and.stars")
                                                                .font(.system(size: 22, weight: .semibold))
                                                                .foregroundColor(emailViewModel.activeSavedFilter?.id == filter.id ? .purple : .vibTextSecondary)
                                                        }
                                                        
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(filter.title)
                                                                .font(.system(size: 19, weight: .semibold, design: .rounded))
                                                                .foregroundColor(emailViewModel.activeSavedFilter?.id == filter.id ? .purple : .vibText)
                                                            Text("Custom filter")
                                                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                                                .foregroundColor(.vibTextSecondary)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        // Remove button
                                                        Button(action: {
                                                            emailViewModel.removeCustomFilter(filter)
                                                        }) {
                                                            Image(systemName: "trash")
                                                                .font(.system(size: 16, weight: .medium))
                                                                .foregroundColor(.vibError)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                        
                                                        // Enhanced checkmark with glow effect
                                                        if emailViewModel.activeSavedFilter?.id == filter.id {
                                                            ZStack {
                        Circle()
                                                                    .fill(Color.purple)
                                                                    .frame(width: 32, height: 32)
                                                                    .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 4)
                                                                Image(systemName: "checkmark")
                                                                    .font(.system(size: 16, weight: .bold))
                                                                    .foregroundColor(.white)
                                                            }
                                                        }
                                                    }
                                                    .padding(.horizontal, 18)
                                                    .padding(.vertical, 18)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 22)
                                                                                                                    .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: emailViewModel.activeSavedFilter?.id == filter.id ? 
                                                                    [Color.vibSurface.opacity(0.3), Color.vibSurface.opacity(0.2)] : 
                                                                    [Color.vibSurface.opacity(0.2), Color.vibSurface.opacity(0.1)]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .shadow(color: .black.opacity(emailViewModel.activeSavedFilter?.id == filter.id ? 0.2 : 0.1), radius: 15, x: 0, y: 8)
                                                    )
                            .overlay(
                                                        RoundedRectangle(cornerRadius: 22)
                                                                                                                    .stroke(
                                                            emailViewModel.activeSavedFilter?.id == filter.id ? Color.purple.opacity(0.5) : Color.clear,
                                                            lineWidth: 2.5
                                                        )
                                                    )
                                                                                                            .scaleEffect(emailViewModel.activeSavedFilter?.id == filter.id ? 1.02 : 1.0)
                                                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: emailViewModel.activeSavedFilter)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 32)
                                .padding(.horizontal, 28)
                            }
                            
                            // Enhanced gradient divider
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.vibPrimary.opacity(0.3), Color.clear]), startPoint: .leading, endPoint: .trailing))
                                .frame(height: 1)
                                .padding(.horizontal, 28)
                            // Top Action Buttons
            HStack {
                                if !emailViewModel.activeFilters.isEmpty {
                Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            emailViewModel.clearAllFilters()
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "arrow.uturn.backward")
                                                .font(.system(size: 16, weight: .semibold))
                                            Text("Clear All")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        }
                                        .foregroundColor(.vibPrimary)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 14)
                                        .background(
                                            Capsule()
                                                .fill(LinearGradient(gradient: Gradient(colors: [Color.vibPrimary.opacity(0.2), Color.vibPrimary.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .shadow(color: .vibPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 24)

                            // Temporary Custom Filter
                            if let currentFilter = emailViewModel.currentCustomFilter {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Current Temporary Filter")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.vibTextSecondary)
                                        .padding(.horizontal, 28)
                                    
                                    HStack {
                                        HStack(spacing: 8) {
                                            Image(systemName: "wand.and.stars")
                                                .foregroundColor(.vibPrimary)
                                            Text(currentFilter.title)
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundColor(.vibText)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule().fill(Color.vibPrimary.opacity(0.10))
                                        )
                
                Spacer()
                
                                        Button(action: {
                                            emailViewModel.clearCustomFilter()
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.vibError)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal, 28)
                                }
                                .padding(.bottom, 12)
                            }
                            
                            // Bottom Action Buttons
                            HStack {
                                // Custom Filter Button (Bottom Left)
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingCustomFilterChat = true
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Custom Filter")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 26)
                                    .padding(.vertical, 16)
                                    .background(
                                        ZStack {
                                            // Base gradient
                                            Capsule()
                                                .fill(LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.purple.opacity(0.9),
                                                        Color.blue.opacity(0.8),
                                                        Color.purple.opacity(0.7)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                            
                                            // Animated overlay
                                            Capsule()
                                                .fill(LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.clear,
                                                        Color.white.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .animation(
                                                    Animation.easeInOut(duration: 2.0)
                                                        .repeatForever(autoreverses: true),
                                                    value: UUID()
                                                )
                                        }
                                    )
                                    .shadow(color: .purple.opacity(0.4), radius: 15, x: 0, y: 8)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.6),
                                                        Color.white.opacity(0.3),
                                                        Color.white.opacity(0.6)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .sheet(isPresented: $showingCustomFilterChat) {
                                    CustomFilterChatView()
                                }
                                
                                Spacer()
                                
                                // Apply Button (Bottom Right)
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingFilterSheet = false
                                    }
                                }) {
                HStack(spacing: 8) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text("Apply")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 36)
                                    .padding(.vertical, 16)
                                    .background(
                                        Capsule()
                                            .fill(LinearGradient(gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                                            .shadow(color: .vibPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.vibPrimary.opacity(0.5), lineWidth: 2.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 28)
                            .padding(.bottom, 28)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.vibSurface.opacity(0.85))
                                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
                        )
                        .padding(.vertical, 24)
                        .padding(.horizontal, 0)
                    }
                }
            }
            
            // Filter suggestion chips with proper spacing
            VStack(spacing: 0) {
                // Add spacing between header and filter chips
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Filter button
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Filter")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.vibPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.vibPrimary.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Sort button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingSortOptions.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Sort")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.vibPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.vibPrimary.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        ForEach(emailViewModel.allFilterSuggestions, id: \.self) { suggestion in
                            Button(action: {
                                switch suggestion {
                                case .category(let filter):
                                    emailViewModel.toggleFilter(filter)
                                case .custom(let filter):
                                    if emailViewModel.activeSavedFilter?.id == filter.id {
                                        emailViewModel.clearCustomFilter()
                                    } else {
                                        emailViewModel.applyCustomFilter(filter)
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: suggestion.icon)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(suggestion.displayName)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(isSuggestionActive(suggestion) ? .white : suggestion.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSuggestionActive(suggestion) ? suggestion.color : suggestion.color.opacity(0.12))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        if let custom = emailViewModel.currentCustomFilter {
                            HStack(spacing: 6) {
                                // Animated sparkle effect
                                ZStack {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                Text(custom.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                Button(action: { emailViewModel.clearCustomFilter() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    // Base gradient matching the Custom Filter button
                                    Capsule()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.purple.opacity(0.9),
                                                Color.blue.opacity(0.8),
                                                Color.purple.opacity(0.7)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                    
                                    // Animated overlay for shimmer effect
                                    Capsule()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.2),
                                                Color.clear,
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .animation(
                                            Animation.easeInOut(duration: 2.0)
                                                .repeatForever(autoreverses: true),
                                            value: UUID()
                                        )
                                }
                            )
                            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.6)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: custom.id)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                
                // Add bottom spacing before email list
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 12)
            }
            .frame(height: 36)
        }
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
    
    private var sortOptionsView: some View {
        VStack(spacing: 0) {
            ForEach(EmailViewModel.SortOption.allCases, id: \.self) { option in
                Button(action: {
                    emailViewModel.sortOption = option
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSortOptions = false
                    }
                }) {
                    HStack {
                        // Icon for each sort option
                        Image(systemName: sortIcon(for: option))
                            .foregroundColor(sortIconColor(for: option))
                            .font(.caption)
                        
                        Text(option.rawValue)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        
                        // Description for priority sort
                        if option == .priority {
                            Text("(High to Low)")
                                .font(.caption2)
                                .foregroundColor(.vibTextSecondary)
                        }
                        
                        Spacer()
                        
                        if emailViewModel.sortOption == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.vibPrimary)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(emailViewModel.sortOption == option ? Color.vibPrimary.opacity(0.1) : Color.vibSurface.opacity(0.8))
                )
                
                if option != EmailViewModel.SortOption.allCases.last {
                    Divider()
                        .padding(.leading, 20)
                        .background(Color.vibGrayMedium.opacity(0.3))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vibSurface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    private var emailListView: some View {
        Group {
            if emailViewModel.isLoading || (emailViewModel.emails.isEmpty && emailViewModel.searchText.isEmpty) {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .vibPrimary))
                        .scaleEffect(1.2)
                    
                    Text("Loading emails...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.8).delay(0.5), value: animateContent)
            } else if emailViewModel.filteredEmails.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "envelope")
                        .font(.system(size: 60))
                        .foregroundColor(.vibTextSecondary)
                        .opacity(0.6)
                    
                    Text("No emails found")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                    
                    if !emailViewModel.searchText.isEmpty {
                        Text("Try adjusting your search terms")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.8).delay(0.5), value: animateContent)
            } else {
                List {
                        if emailViewModel.sortOption == .priority {
                        // Group by priority when sorting by priority
                        ForEach(groupedEmails, id: \.priority) { group in
                            Section(header: prioritySectionHeader(for: group.priority)) {
                                ForEach(group.emails) { email in
                                    EmailRowView(
                                        email: email,
                                        isSelectMode: isSelectMode,
                                        isSelected: selectedEmails.contains(email.id),
                                        onSelectionToggle: { toggleEmailSelection(email.id) },
                                        onEmailTap: { emailViewModel.selectedEmail = email; showingEmailDetail = true }
                                    )
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button(action: {
                                                if email.isRead {
                                                    print("📧 Marking email as unread: \(email.subject)")
                                                    emailViewModel.markAsUnread(email)
                                                } else {
                                                    print("📧 Marking email as read: \(email.subject)")
                                                emailViewModel.markAsRead(email)
                                                }
                                            }) {
                                                Image(systemName: email.isRead ? "envelope.badge" : "envelope.open")
                                            }
                                            .tint(.vibPrimary)
                                            
                                            Button(action: {
                                                // Star/unstar
                                                Task { await emailViewModel.toggleStar(email) }
                                            }) {
                                                Image(systemName: email.isStarred ? "star.slash" : "star.fill")
                                            }
                                            .tint(.vibPrimary)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(action: {
                                                if email.isArchived {
                                                    emailViewModel.unarchiveEmail(email)
                                                } else {
                                                    emailViewModel.archiveEmail(email)
                                                }
                                            }) {
                                                Image(systemName: email.isArchived ? "tray.and.arrow.up" : "archivebox")
                                            }
                                            .tint(.gray)
                                            
                                            Button(action: {
                                                // Forward
                                            }) {
                                                Image(systemName: "arrowshape.turn.up.right")
                                            }
                                            .tint(.vibSuccess)
                                            
                                            Button(action: {
                                                emailViewModel.textToSpeechService.speakEmail(email)
                                            }) {
                                                Image(systemName: "speaker.wave.2")
                                            }
                                            .tint(.vibPrimary)
                                        }
                                        .onLongPressGesture(minimumDuration: 0.5) {
                                            // Show quick actions menu
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                // Trigger haptic feedback
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                                impactFeedback.impactOccurred()
                                            }
                                        }
                                        .contextMenu {
                                            Button(action: {
                                                if email.isRead {
                                                    print("📧 Marking email as unread: \(email.subject)")
                                                    emailViewModel.markAsUnread(email)
                                                } else {
                                                    print("📧 Marking email as read: \(email.subject)")
                                                emailViewModel.markAsRead(email)
                                                }
                                            }) {
                                                Label(email.isRead ? "Mark as Unread" : "Mark as Read", systemImage: email.isRead ? "envelope.badge" : "envelope.open")
                                            }
                                            
                                            Button(action: {
                                                Task { await emailViewModel.toggleStar(email) }
                                            }) {
                                                Label(email.isStarred ? "Remove Star" : "Star", 
                                                      systemImage: email.isStarred ? "star.slash" : "star.fill")
                                            }
                                            
                                            Button(action: {
                                                emailViewModel.textToSpeechService.speakEmail(email)
                                            }) {
                                                Label("Read Aloud", systemImage: "speaker.wave.2")
                                            }
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                // Reply
                                            }) {
                                                Label("Reply", systemImage: "arrowshape.turn.up.left")
                                            }
                                            
                                            Button(action: {
                                                // Forward
                                            }) {
                                                Label("Forward", systemImage: "arrowshape.turn.up.right")
                                            }
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                if email.isArchived {
                                                    emailViewModel.unarchiveEmail(email)
                                                } else {
                                                    emailViewModel.archiveEmail(email)
                                                }
                                            }) {
                                                Label(email.isArchived ? "Unarchive" : "Archive", 
                                                      systemImage: email.isArchived ? "tray.and.arrow.up" : "archivebox")
                                            }
                                            
                                            Button(action: {
                                                if email.isTrash {
                                                    emailViewModel.restoreFromTrash(email)
                                                } else {
                                                    emailViewModel.deleteEmail(email)
                                                }
                                            }) {
                                                if email.isTrash {
                                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                                } else {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            }
                                        }
                                }
                            }
                        } else {
                        // Flat list when sorting by date
                        ForEach(emailViewModel.filteredEmails) { email in
                                EmailRowView(
                                    email: email,
                                    isSelectMode: isSelectMode,
                                    isSelected: selectedEmails.contains(email.id),
                                    onSelectionToggle: { toggleEmailSelection(email.id) },
                                    onEmailTap: { emailViewModel.selectedEmail = email; showingEmailDetail = true }
                                )
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button(action: {
                                        if email.isRead {
                                            print("📧 Marking email as unread: \(email.subject)")
                                            emailViewModel.markAsUnread(email)
                                        } else {
                                            print("📧 Marking email as read: \(email.subject)")
                                            emailViewModel.markAsRead(email)
                                        }
                                        }) {
                                            Image(systemName: email.isRead ? "envelope.badge" : "envelope.open")
                                        }
                                        .tint(.vibPrimary)
                                        
                                        Button(action: {
                                            // Star/unstar
                                        Task { await emailViewModel.toggleStar(email) }
                                        }) {
                                            Image(systemName: email.isStarred ? "star.slash" : "star.fill")
                                        }
                                        .tint(.vibPrimary)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(action: {
                                            if email.isArchived {
                                                emailViewModel.unarchiveEmail(email)
                                            } else {
                                                emailViewModel.archiveEmail(email)
                                            }
                                        }) {
                                            Image(systemName: email.isArchived ? "tray.and.arrow.up" : "archivebox")
                                        }
                                        .tint(.gray)
                                        
                                        Button(action: {
                                            // Forward
                                        }) {
                                            Image(systemName: "arrowshape.turn.up.right")
                                        }
                                        .tint(.vibSuccess)
                                        
                                        Button(action: {
                                            emailViewModel.textToSpeechService.speakEmail(email)
                                        }) {
                                            Image(systemName: "speaker.wave.2")
                                        }
                                        .tint(.vibPrimary)
                                        
                                    Button(action: {
                                        // Reply
                                    }) {
                                        Image(systemName: "arrowshape.turn.up.left")
                                    }
                                    .tint(.vibSuccess)
                                    }
                                    .onLongPressGesture(minimumDuration: 0.5) {
                                        // Show quick actions menu
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            // Trigger haptic feedback
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                    .contextMenu {
                                        Button(action: {
                                        if email.isRead {
                                            print("📧 Marking email as unread: \(email.subject)")
                                            emailViewModel.markAsUnread(email)
                                        } else {
                                            print("📧 Marking email as read: \(email.subject)")
                                            emailViewModel.markAsRead(email)
                                        }
                                        }) {
                                            Label(email.isRead ? "Mark as Unread" : "Mark as Read", systemImage: email.isRead ? "envelope.badge" : "envelope.open")
                                        }
                                        
                                        Button(action: {
                                        Task { await emailViewModel.toggleStar(email) }
                                        }) {
                                            Label(email.isStarred ? "Remove Star" : "Star", 
                                                  systemImage: email.isStarred ? "star.slash" : "star.fill")
                                        }
                                        
                                        Button(action: {
                                            emailViewModel.textToSpeechService.speakEmail(email)
                                        }) {
                                            Label("Read Aloud", systemImage: "speaker.wave.2")
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            // Reply
                                        }) {
                                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                                        }
                                        
                                        Button(action: {
                                            // Forward
                                        }) {
                                            Label("Forward", systemImage: "arrowshape.turn.up.right")
                                        }
                                        
                                        Divider()
                                        
                                        Button(action: {
                                            if email.isArchived {
                                                emailViewModel.unarchiveEmail(email)
                                            } else {
                                                emailViewModel.archiveEmail(email)
                                            }
                                        }) {
                                            Label(email.isArchived ? "Unarchive" : "Archive", 
                                                  systemImage: email.isArchived ? "tray.and.arrow.up" : "archivebox")
                                        }
                                        
                                        Button(action: {
                                            if email.isTrash {
                                                emailViewModel.restoreFromTrash(email)
                                            } else {
                                                emailViewModel.deleteEmail(email)
                                            }
                                        }) {
                                            if email.isTrash {
                                                Label("Restore", systemImage: "arrow.uturn.backward")
                                            } else {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    // Safe pull to refresh with proper task cancellation
                    emailViewModel.refreshEmailsSafely()
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.8).delay(0.6), value: animateContent)
            }
        }
        .overlay(
            // Enhanced floating buttons with multi-select support
            VStack {
                Spacer()
                HStack {
                    // Select button (bottom left)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isSelectMode.toggle()
                            if !isSelectMode {
                                selectedEmails.removeAll()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isSelectMode ? "xmark.circle.fill" : "checkmark.circle")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(isSelectMode ? "Cancel" : "Select")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(isSelectMode ? .vibBlack : .vibPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(isSelectMode ? Color.vibPrimary : Color.vibSurface.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: isSelectMode ? .vibPrimary.opacity(0.4) : .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(isSelectMode ? 1.05 : 1.0)
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    // Compose button (bottom right)
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showingCompose = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Compose")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.vibBlack)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
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
                    .scaleEffect(showingCompose ? 0.95 : 1.0)
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
        )
    }
    
    // MARK: - Computed Properties
    
    private var groupedEmails: [EmailGroup] {
        let grouped = Dictionary(grouping: emailViewModel.filteredEmails) { email in
            email.priority
        }
        
        return EmailPriority.allCases.compactMap { priority in
            guard let emails = grouped[priority], !emails.isEmpty else { return nil }
            return EmailGroup(priority: priority, emails: emails)
        }
    }
    
    private func prioritySectionHeader(for priority: EmailPriority) -> some View {
        HStack {
            Image(systemName: priority.icon)
                .foregroundColor(priorityColor(for: priority))
                .font(.caption)
            
            Text(priority.rawValue)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(priorityColor(for: priority))
            
            Text("(\(groupedEmails.first { $0.priority == priority }?.emails.count ?? 0))")
                .font(.caption2)
                .foregroundColor(.vibTextSecondary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(priorityColor(for: priority).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(priorityColor(for: priority).opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
    
    private func priorityColor(for priority: EmailPriority) -> Color {
        switch priority {
        case .urgent:
            return .vibError
        case .high:
            return .vibWarning
        case .medium:
            return .vibPrimary
        case .low:
            return .vibGrayMedium
        case .update:
            return .vibInfo
        }
    }
    
    private func sortIcon(for option: EmailViewModel.SortOption) -> String {
        switch option {
        case .priority:
            return "exclamationmark.triangle.fill"
        case .date:
            return "calendar"
        }
    }
    
    private func sortIconColor(for option: EmailViewModel.SortOption) -> Color {
        switch option {
        case .priority:
            return .vibWarning
        case .date:
            return .vibPrimary
        }
    }
    
    private func isSuggestionActive(_ suggestion: FilterSuggestion) -> Bool {
        switch suggestion {
        case .category(let filter):
            return emailViewModel.activeFilters.contains(filter)
        case .custom(let filter):
            return emailViewModel.activeSavedFilter?.id == filter.id
        }
    }
    
    // MARK: - Batch Actions Toolbar
    
    private var batchActionsToolbar: some View {
        HStack(spacing: 0) {
            // Selected count
            VStack(alignment: .leading, spacing: 1) {
                Text("\(selectedEmails.count) selected")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibText)
                Text("Tap actions below")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
            }
            
            Spacer()
            
            // Batch action buttons
            HStack(spacing: 8) {
                // Mark as Read/Unread
                Button(action: {
                    performBatchAction(.toggleRead)
                }) {
                    Image(systemName: hasUnreadSelected ? "envelope.open" : "envelope.badge")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vibPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.vibSurface.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Star/Unstar
                Button(action: {
                    performBatchAction(.toggleStar)
                }) {
                    Image(systemName: hasUnstarredSelected ? "star" : "star.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vibPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.vibSurface.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Archive
                Button(action: {
                    performBatchAction(.archive)
                }) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.vibPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.vibSurface.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // Delete
                Button(action: {
                    performBatchAction(.delete)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.vibSurface.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vibSurface.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
    
    // MARK: - Batch Action Helpers
    
    private var hasUnreadSelected: Bool {
        selectedEmails.contains { emailId in
            emailViewModel.emails.first(where: { $0.id == emailId })?.isRead == false
        }
    }
    
    private var hasUnstarredSelected: Bool {
        selectedEmails.contains { emailId in
            emailViewModel.emails.first(where: { $0.id == emailId })?.isStarred == false
        }
    }
    
    private enum BatchAction {
        case toggleRead
        case toggleStar
        case archive
        case delete
    }
    
    private func performBatchAction(_ action: BatchAction) {
        let selectedEmailObjects = emailViewModel.emails.filter { selectedEmails.contains($0.id) }
        
        Task {
            for email in selectedEmailObjects {
                switch action {
                case .toggleRead:
                    if email.isRead {
                        await emailViewModel.markAsUnread(email)
                    } else {
                        await emailViewModel.markAsRead(email)
                    }
                case .toggleStar:
                    await emailViewModel.toggleStar(email)
                case .archive:
                    await emailViewModel.archiveEmail(email)
                case .delete:
                    if email.isTrash {
                        await emailViewModel.restoreFromTrash(email)
                    } else {
                        await emailViewModel.deleteEmail(email)
                    }
                }
            }
        }
        
        // Clear selection and exit select mode
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            selectedEmails.removeAll()
            isSelectMode = false
        }
    }
    
    // MARK: - Selection Helpers
    
    private func toggleEmailSelection(_ emailId: String) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if selectedEmails.contains(emailId) {
                selectedEmails.remove(emailId)
            } else {
                selectedEmails.insert(emailId)
            }
        }
    }
}

// MARK: - Supporting Types

struct EmailGroup {
    let priority: EmailPriority
    let emails: [Email]
}

struct EmailRowView: View {
    let email: Email
    let isSelectMode: Bool
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    let onEmailTap: () -> Void
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var animateRow = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Selection indicator (appears in select mode)
            if isSelectMode {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .vibPrimary : .vibGrayMedium)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Enhanced sender avatar with priority indicator
            VStack(spacing: 3) {
                ZStack {
                    // Glow effect for priority
                    if email.priority == .urgent || email.priority == .high {
                Circle()
                            .fill(priorityColor.opacity(0.3))
                            .frame(width: 46, height: 46)
                            .blur(radius: 8)
                            .scaleEffect(animateRow ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateRow)
                    }
                    
                    // Profile image or fallback circle
                    if let profileImageURL = email.senderProfileImageURL {
                        AsyncImage(url: profileImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.vibPrimary.opacity(0.15))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.vibPrimary)
                                )
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1.5)
                        )
                    } else {
                        // Fallback to letter circle
                        Circle()
                            .fill(Color.vibPrimary.opacity(0.15))
                            .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(email.sender.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.vibPrimary)
                    )
                            .overlay(
                                Circle()
                                    .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                }
                
                // Priority indicator dot
                if email.priority == .urgent || email.priority == .high {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: priorityColor.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Header row with sender, time, and actions
                HStack {
                    Text(email.sender)
                        .font(.system(size: 15, weight: email.isRead ? .medium : .semibold, design: .rounded))
                        .foregroundColor(email.isRead ? .vibTextSecondary : .vibText)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 6) {
                        // Always show AI priority tag
                        PriorityTagView(
                            priority: email.priority,
                            isAnalyzing: emailViewModel.analyzingEmails.contains(email.id)
                        )
                        // Star indicator (always visible, tappable)
                        Button(action: {
                            Task { await emailViewModel.toggleStar(email) }
                        }) {
                            Image(systemName: email.isStarred ? "star.fill" : "star")
                                .foregroundColor(email.isStarred ? .vibPrimary : .vibGrayMedium)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Text(email.timestamp, style: .relative)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                }
                // Subject line
                HStack {
                    Text(email.subject)
                        .font(.system(size: 14, weight: email.isRead ? .medium : .semibold, design: .rounded))
                        .foregroundColor(email.isRead ? .vibTextSecondary : .vibText)
                        .lineLimit(1)
                    Spacer()
                    // Action required indicator
                    if email.requiresAction {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.vibWarning)
                            .font(.caption)
                    }
                }
                // Content preview with better formatting
                HStack(alignment: .top) {
                    Text(email.content)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.vibTextSecondary.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            
            // Vertically centered trash can with modern styling
            VStack {
                Spacer()
                Button(action: {
                    if email.isTrash {
                        emailViewModel.restoreFromTrash(email)
                    } else {
                        emailViewModel.deleteEmail(email)
                    }
                }) {
                    Image(systemName: email.isTrash ? "arrow.uturn.backward" : "trash")
                        .foregroundColor(email.isTrash ? .vibPrimary : .vibError)
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
        .background(
                    Circle()
                        .fill(Color.vibError.opacity(0.1))
                )
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
        .overlay(
                    RoundedRectangle(cornerRadius: 16)
                .stroke(
                    priorityBorderColor,
                    lineWidth: priorityBorderWidth
                )
        )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animateRow = true
            }
        }
        .onTapGesture {
            if isSelectMode {
                onSelectionToggle()
            } else {
                onEmailTap()
            }
        }
    }
    
    private var priorityColor: Color {
        switch email.priority {
        case .urgent:
            return .vibError
        case .high:
            return .vibWarning
        case .medium:
            return .vibPrimary
        case .low:
            return .vibSuccess
        case .update:
            return .vibInfo
        }
    }
    
    private var backgroundColor: Color {
        if !email.isRead {
            return Color.vibPrimary.opacity(0.08)
        }
        
        switch email.priority {
        case .urgent:
            return Color.vibError.opacity(0.08)
        case .high:
            return Color.vibWarning.opacity(0.08)
        case .medium:
            return Color.vibSurface.opacity(0.3)
        case .low:
            return Color.vibSuccess.opacity(0.05)
        case .update:
            return Color.vibInfo.opacity(0.05)
        }
    }
    
    private var priorityBorderColor: Color {
        switch email.priority {
        case .urgent:
            return Color.vibError.opacity(0.4)
        case .high:
            return Color.vibWarning.opacity(0.3)
        case .medium:
            return Color.vibPrimary.opacity(0.2)
        case .low:
            return Color.vibSuccess.opacity(0.2)
        case .update:
            return Color.vibInfo.opacity(0.2)
        }
    }
    
    private var priorityBorderWidth: CGFloat {
        switch email.priority {
        case .urgent:
            return 2.0
        case .high:
            return 1.5
        case .medium:
            return 1.0
        case .low:
            return 0.5
        case .update:
            return 0.5
        }
    }
}

// Custom Filter Chat View
@MainActor
private struct CustomFilterChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @State private var showingSaveDialog = false
    @State private var showingFilterOptions = false
    @State private var filterTitle = ""
    @State private var currentFilterQuery = ""
    @State private var pendingCustomFilter: CustomEmailFilter?
    @State private var isSavingFilter = false
    @StateObject private var speechService = SpeechService()
    
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
            .background(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Filter")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.vibText)
                        Text("Chat with AI to create filters")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.vibSurface.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.vibTextSecondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 32)
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
                
                // Gradient divider
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.vibPrimary.opacity(0.3), Color.clear]), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .padding(.horizontal, 28)
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Chat messages
                            ForEach(messages) { message in
                                ChatMessageView(message: message) {
                                    if let filter = message.suggestedFilter {
                                        currentFilterQuery = filter
                                        filterTitle = ""
                                        showingSaveDialog = true
                                    }
                                }
                            }
                            
                            // Typing indicator
                            if isTyping {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.vibPrimary)
                                    Text("AI is thinking...")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.vibTextSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.vibSurface.opacity(0.3))
                                )
                                .padding(.horizontal, 28)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 0) {
                    // Gradient divider
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.vibPrimary.opacity(0.3), Color.clear]), startPoint: .leading, endPoint: .trailing))
                        .frame(height: 1)
                        .padding(.horizontal, 28)
                    
                    HStack(spacing: 16) {
                        // Voice button
                        Button(action: {
                            if speechService.isRecording {
                                speechService.stopRecording()
                                messageText = speechService.processTranscribedText(speechService.transcribedText)
                            } else {
                                speechService.startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(speechService.isRecording ? Color.red.opacity(0.2) : Color.vibPrimary.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(speechService.isRecording ? .red : .vibPrimary)
                                
                                // Recording indicator
                                if speechService.isRecording {
                                    Circle()
                                        .stroke(Color.red, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                        .scaleEffect(1.2)
                                        .opacity(0.6)
                                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechService.isRecording)
                                }
                            }
                            .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onReceive(speechService.$transcribedText) { text in
                            if !text.isEmpty && !speechService.isRecording {
                                messageText = speechService.processTranscribedText(text)
                            }
                        }
                        .onReceive(speechService.$errorMessage) { error in
                            if let error = error {
                                // Add error message to chat
                                let errorMessage = ChatMessage(
                                    id: UUID(),
                                    text: "❌ Voice input error: \(error)",
                                    isUser: false,
                                    timestamp: Date()
                                )
                                messages.append(errorMessage)
                            }
                        }
                        
                        // Text input
                        HStack {
                            TextField("Type your filter request...", text: $messageText, axis: .vertical)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.vibText)
                                .lineLimit(1...4)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.vibSurface.opacity(0.3))
                                )
                            
                            // Send button
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .vibTextSecondary : .vibPrimary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                }
            }
        }
        .onAppear {
            // Add welcome message with examples
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                messages.append(ChatMessage(
                    id: UUID(),
                    text: "Hi! I'm your AI filter assistant. Tell me what kind of emails you want to see and I'll help you create a custom filter.\n\n💡 Try asking for:\n• \"Show me purchase confirmations and receipts\"\n• \"Emails from my boss or manager\"\n• \"Important project updates and deadlines\"\n• \"Meeting invitations and calendar events\"\n• \"Newsletters and marketing emails\"\n• \"Banking and financial statements\"\n• \"Travel confirmations and bookings\"\n• \"Social media notifications\"",
                    isUser: false,
                    timestamp: Date()
                ))
            }
        }
        .sheet(isPresented: $showingSaveDialog) {
            SaveFilterDialog(
                filterTitle: $filterTitle,
                filterQuery: currentFilterQuery,
                isSaving: $isSavingFilter,
                onSave: { title in
                    guard !isSavingFilter else { return }
                    
                    isSavingFilter = true
                    
                    // Haptic feedback for success
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    let filter = CustomEmailFilter(title: title, query: currentFilterQuery)
                    emailViewModel.saveCustomFilter(filter)
                    emailViewModel.applyCustomFilter(filter)
                    
                    // Add success message to chat
                    let successMessage = ChatMessage(
                        id: UUID(),
                        text: "✅ Filter saved and applied! I've saved '\(title)' as a permanent filter and applied it to your emails.",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(successMessage)
                    
                    // Reset saving state and dismiss the chat after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isSavingFilter = false
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showingFilterOptions) {
            FilterOptionsDialog(
                customFilter: pendingCustomFilter!,
                onApplyTemporarily: { filter in
                    // Haptic feedback for success
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    emailViewModel.applyCustomFilter(filter)
                    showingFilterOptions = false
                    
                    // Add success message to chat
                    let successMessage = ChatMessage(
                        id: UUID(),
                        text: "✅ Filter applied! I've applied '\(filter.title)' to your emails. You can see the results in your email list.",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(successMessage)
                    
                    // Dismiss the chat after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                },
                onSavePermanently: { filter in
                    filterTitle = filter.title
                    showingFilterOptions = false
                    showingSaveDialog = true
                }
            )
        }
    }
    
    private func showFilterOptions(for filter: CustomEmailFilter) {
        pendingCustomFilter = filter
        showingFilterOptions = true
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID(),
            text: trimmedText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        messageText = ""
        
        // Generate AI response
        isTyping = true
        Task {
            let aiResponse = await generateAIResponse(to: trimmedText)
            
            await MainActor.run {
                isTyping = false
                
                let aiMessage = ChatMessage(
                    id: UUID(),
                    text: aiResponse.text,
                    isUser: false,
                    timestamp: Date(),
                    suggestedFilter: aiResponse.filter
                )
                messages.append(aiMessage)
                
                if let filter = aiResponse.filter {
                    currentFilterQuery = filter
                    // Show options to apply temporarily or save permanently
                    let title = aiResponse.title ?? "AI Generated Filter"
                    let customFilter = CustomEmailFilter(title: title, query: filter)
                    showFilterOptions(for: customFilter)
                }
            }
        }
    }
    
    private func generateAIResponse(to userInput: String) async -> AIResponse {
        // Use the AI service to analyze emails and generate intelligent filters
        let aiService = AIService()
        let result = await aiService.generateCustomFilter(for: userInput, emails: emailViewModel.emails)
        
        return AIResponse(
            text: result.description,
            filter: result.query,
            title: result.title
        )
    }
    
    private func generateSmartTitle(from userInput: String) -> String {
        let words = userInput.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.capitalized }
        
        if words.count == 1 {
            return "\(words[0]) Emails"
        } else if words.count <= 3 {
            return words.joined(separator: " ")
        } else {
            return "Custom Filter"
        }
    }
}

// Chat message model
struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    let suggestedFilter: String?
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date, suggestedFilter: String? = nil) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.suggestedFilter = suggestedFilter
    }
}

// AI response model
struct AIResponse {
    let text: String
    let filter: String?
    let title: String?
    
    init(text: String, filter: String?, title: String? = nil) {
        self.text = text
        self.filter = filter
        self.title = title
    }
}

// Chat message view
struct ChatMessageView: View {
    let message: ChatMessage
    let onSaveFilter: (() -> Void)?
    
    init(message: ChatMessage, onSaveFilter: (() -> Void)? = nil) {
        self.message = message
        self.onSaveFilter = onSaveFilter
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 8) {
                    Text(message.text)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                    
                    if let filter = message.suggestedFilter {
                        Button(action: {
                            onSaveFilter?()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Save Filter")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.vibPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.vibPrimary.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.vibPrimary)
                        Text("AI Assistant")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                    
                    Text(message.text)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.vibText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.vibSurface.opacity(0.3))
                        )
                }
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 28)
    }
}

// Filter options dialog
struct FilterOptionsDialog: View {
    let customFilter: CustomEmailFilter
    let onApplyTemporarily: (CustomEmailFilter) -> Void
    let onSavePermanently: (CustomEmailFilter) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header with filter info
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.3),
                                        Color.blue.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 48, height: 48)
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.vibPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(customFilter.title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.vibText)
                            Text("AI Generated Filter")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.vibTextSecondary)
                        }
                        Spacer()
                    }
                    
                    Text("How would you like to apply this filter?")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Apply temporarily button
                    Button(action: {
                        onApplyTemporarily(customFilter)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apply Temporarily")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Text("Use this filter now, but don't save it")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: .vibPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Save permanently button
                    Button(action: {
                        onSavePermanently(customFilter)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 16, weight: .semibold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Save Permanently")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                Text("Save this filter for future use")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Cancel button
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.vibTextSecondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.vibSurface.opacity(0.3))
                )
                .buttonStyle(PlainButtonStyle())
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.vibSurface.opacity(0.95))
            )
            .padding(.horizontal, 40)
        }
    }
}

// Save filter dialog
struct SaveFilterDialog: View {
    @Binding var filterTitle: String
    let filterQuery: String
    @Binding var isSaving: Bool
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Animated gradient background overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.vibBlack.opacity(0.8),
                    Color.vibGrayDark.opacity(0.6),
                    Color.vibBlack.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .background(.ultraThinMaterial)
            
            VStack(spacing: 0) {
                // Header with icon
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Save Custom Filter")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.vibText)
                        Text("Create a permanent filter for quick access")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                    Spacer()
                }
                .padding(.top, 32)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                
                // Gradient divider
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.clear, Color.vibPrimary.opacity(0.3), Color.clear]), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .padding(.horizontal, 28)
                
                // Content
                VStack(spacing: 24) {
                    // Filter preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter Preview")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibText)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.vibPrimary)
                            Text(filterQuery)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.vibTextSecondary)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.vibSurface.opacity(0.3))
                        )
                    }
                    
                    // Filter name input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filter Name")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.vibText)
                        
                        TextField("Enter a descriptive name", text: $filterTitle)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.vibText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.vibSurface.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .onSubmit {
                                if !filterTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving {
                                    saveFilter()
                                }
                            }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.vibSurface.opacity(0.3))
                    )
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSaving)
                    
                    Button(action: saveFilter) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(isSaving ? "Saving..." : "Save Filter")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.vibPrimary, Color.vibPrimary.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(isSaving ? 0.6 : 1.0)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(filterTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.vibSurface.opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
        }
    }
    
    private func saveFilter() {
        guard !isSaving else { return }
        
        onSave(filterTitle)
    }
}

// Helper for filter descriptions
private func filterDescription(for filter: EmailCategoryFilter) -> String {
    switch filter {
    case .inbox: return "Show inbox emails."
    case .starred: return "Show only starred emails."
    case .sent: return "Show emails you have sent."
    case .trash: return "Show emails in the trash."
    case .archive: return "Show archived emails."
    case .unread: return "Show only unread emails."
    case .important: return "Show important emails."
    }
}

#Preview {
    EmailListView()
        .environmentObject(EmailViewModel())
} 
