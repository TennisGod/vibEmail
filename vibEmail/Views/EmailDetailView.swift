import SwiftUI

struct EmailDetailView: View {
    let email: Email
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingReply = false
    @State private var showingForward = false
    @State private var showingToneSelection = false
    @State private var selectedAction: EmailAction?
    @State private var animateHeader = true
    @State private var animateContent = false
    @State private var animateActions = false
    
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
                ForEach(0..<12, id: \.self) { index in
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
                
                // Email content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Email metadata with modern card design
                        metadataView
                        
                        // Priority tag
                        PriorityTagView(
                            priority: email.priority,
                            isAnalyzing: emailViewModel.analyzingEmails.contains(email.id)
                        )
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeIn(duration: 0.8).delay(0.3), value: animateContent)
                        
                        // Email content
                        contentView
                        
                        // Attachments
                        if !email.attachments.isEmpty {
                            attachmentsView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Action buttons with modern styling
                actionButtonsView
            }
            
            // Floating Audio Player - positioned above action buttons
            VStack {
                Spacer()
                AudioPlayerView(textToSpeechService: emailViewModel.textToSpeechService)
                    .environmentObject(emailViewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingToneSelection) {
            if let action = selectedAction {
                ToneSelectionView(action: action, email: email)
                    .environmentObject(emailViewModel)
            }
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
                    animateActions = true
                }
            }
            
            // Automatically mark email as read when opened (industry standard)
            if !email.isRead {
                print("📧 Auto-marking email as read: \(email.subject)")
                emailViewModel.markAsRead(email)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // Back button with modern styling
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
            
            // Date and time with modern styling
            VStack(alignment: .trailing, spacing: 4) {
                Text(email.timestamp, style: .date)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
                
                Text(email.timestamp, style: .time)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.vibSurface.opacity(0.5))
            )
            
            // Menu button with modern styling
            Menu {
                Button(action: {
                    print("⭐ Star/Unstar button pressed for email: \(email.subject)")
                    print("⭐ Current starred status: \(email.isStarred)")
                    Task { await emailViewModel.toggleStar(email) }
                }) {
                    Label(email.isStarred ? "Unstar" : "Star", systemImage: email.isStarred ? "star.slash" : "star")
                }
                
                Button(action: {
                    print("🔘 Archive/Unarchive button pressed for email: \(email.subject)")
                    print("🔘 Current archived status: \(email.isArchived)")
                    
                    if email.isArchived {
                        print("🔘 Calling unarchiveEmail")
                        emailViewModel.unarchiveEmail(email)
                    } else {
                        print("🔘 Calling archiveEmail")
                        emailViewModel.archiveEmail(email)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Label(email.isArchived ? "Unarchive" : "Archive", 
                          systemImage: email.isArchived ? "tray.and.arrow.up" : "archivebox")
                }
                
                Button(action: {
                    print("📧 Mark as Unread button pressed for email: \(email.subject)")
                    print("📧 Current email isRead: \(email.isRead)")
                    print("📧 Total emails in ViewModel: \(emailViewModel.emails.count)")
                    print("📧 Email ID: \(email.id)")
                    
                    // Check if the email exists in the array
                    if let foundEmail = emailViewModel.emails.first(where: { $0.id == email.id }) {
                        print("✅ Found email in array, isRead: \(foundEmail.isRead)")
                    } else {
                        print("❌ Email not found in ViewModel array!")
                    }
                    
                    emailViewModel.markAsUnread(email)
                    print("📧 Function call completed")
                }) {
                    Label("Mark as Unread", systemImage: "envelope.badge")
                }
                
                Divider()
                
                Button(role: email.isTrash ? nil : .destructive, action: {
                    if email.isTrash {
                        print("♻️ Restore button pressed for email: \(email.subject)")
                        emailViewModel.restoreFromTrash(email)
                    } else {
                        print("🗑️ Delete button pressed for email: \(email.subject)")
                        emailViewModel.deleteEmail(email)
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    if email.isTrash {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    } else {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundColor(.vibTextSecondary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.vibSurface.opacity(0.5))
                                        )
 
            }
            .menuStyle(BorderlessButtonMenuStyle())
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
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subject with modern styling
            Text(email.subject)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.vibText)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeIn(duration: 0.8).delay(0.1), value: animateContent)
            
            // Sender info with modern card design
            HStack(spacing: 16) {
                // Enhanced sender avatar
                ZStack {
                    // Glow effect for priority
                    if email.priority == .urgent || email.priority == .high {
                        Circle()
                            .fill(priorityColor.opacity(0.3))
                            .frame(width: 56, height: 56)
                            .blur(radius: 10)
                    }
                    
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(String(email.sender.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.vibPrimary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(email.sender)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibText)
                    
                    Text(email.senderEmail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vibSurface.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .opacity(animateContent ? 1.0 : 0.0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeIn(duration: 0.8).delay(0.2), value: animateContent)
            
            // Recipients with modern styling
            if !email.recipients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("To:")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                    
                    ForEach(email.recipients, id: \.self) { recipient in
                        Text(recipient)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.vibText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.vibSurface.opacity(0.3))
                            )
                    }
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeIn(duration: 0.8).delay(0.25), value: animateContent)
            }
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content:")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.vibTextSecondary)
            
            Text(email.content)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(.vibText)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.vibSurface.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeIn(duration: 0.8).delay(0.35), value: animateContent)
    }
    
    private var attachmentsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments:")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.vibTextSecondary)
            
            ForEach(email.attachments) { attachment in
                HStack(spacing: 12) {
                    // Attachment icon with modern styling
                    Image(systemName: "paperclip")
                        .foregroundColor(.vibPrimary)
                        .font(.title3)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.vibPrimary.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attachment.name)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.vibText)
                        
                        Text(formatFileSize(attachment.size))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.vibTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Download button with modern styling
                    Button("Download") {
                        // Download attachment
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.vibPrimary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.vibSurface.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vibPrimary.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeIn(duration: 0.8).delay(0.4), value: animateContent)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 24) {
            // Reply button with modern styling
            Button(action: {
                selectedAction = .reply
                showingToneSelection = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.title2)
                        .foregroundColor(.vibPrimary)
                    Text("Reply")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.vibPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .vibPrimary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            // Forward button with modern styling
            Button(action: {
                selectedAction = .forward
                showingToneSelection = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.title2)
                        .foregroundColor(.vibPrimary)
                    Text("Forward")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.vibPrimary.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .vibPrimary.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
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
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
        .offset(y: animateActions ? 0 : 20)
        .opacity(animateActions ? 1.0 : 0.0)
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
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

#Preview {
    NavigationView {
        EmailDetailView(email: Email(
            subject: "Project Update - Q4 Goals",
            sender: "Sarah Johnson",
            senderEmail: "sarah.johnson@company.com",
            recipients: ["team@company.com"],
            content: "Hi team, I wanted to share our Q4 goals and priorities. We need to focus on the new product launch and customer acquisition. Please review the attached document and let me know your thoughts.",
            isArchived: false,
            priority: .high,
            requiresAction: true,
            suggestedAction: .reply,
            messageId: "preview_message_1",
            threadId: "preview_thread_1"
        ))
        .environmentObject(EmailViewModel())
    }
} 
