import SwiftUI

struct HelpMessage {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var messageText = ""
    @State private var messages: [HelpMessage] = []
    @State private var animateContent = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
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
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Chat Messages
                    chatMessagesSection
                    
                    // Input Section
                    inputSection
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.vibPrimary)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateContent = true
                }
                addWelcomeMessage()
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.vibPrimary)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.6), value: animateContent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("vibEmail Assistant")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.vibText)
                
                Text("Ask me anything about vibEmail")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.vibTextSecondary)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.vibSuccess)
                .frame(width: 8, height: 8)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.8).delay(0.4), value: animateContent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.vibSurface.opacity(0.9)
                .overlay(
                    Rectangle()
                        .fill(Color.vibPrimary.opacity(0.1))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(0.2), value: animateContent)
    }
    
    private var chatMessagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages, id: \.id) { message in
                        HelpChatMessageView(message: message)
                            .id(message.id)
                    }
                    
                    if isLoading {
                        HStack {
                            TypingIndicatorView()
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.vibPrimary.opacity(0.1))
                .frame(height: 1)
            
            HStack(spacing: 12) {
                TextField("Ask about vibEmail features...", text: $messageText, axis: .vertical)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.vibText)
                    .lineLimit(1...4)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.vibSurface.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                            )
                    )
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .vibTextSecondary : .vibPrimary)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.vibBackground.opacity(0.95))
        }
    }
    
    // MARK: - Functions
    private func addWelcomeMessage() {
        let welcomeMessage = HelpMessage(
            content: "Hi! I'm your vibEmail assistant. I can help you with:\n\n• Email management and organization\n• Smart filtering and AI features\n• Account setup and switching\n• Audio features and accessibility\n• Composing and reply assistance\n• Any other vibEmail questions\n\nWhat would you like to know?",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        let userText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        
        // Add user message
        let userMessage = HelpMessage(
            content: userText,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        messageText = ""
        
        // Show loading and get AI response
        isLoading = true
        getAIResponse(for: userText)
    }
    
    private func getAIResponse(for userQuery: String) {
        Task {
            do {
                let response = try await emailViewModel.generateHelpResponse(for: userQuery)
                
                await MainActor.run {
                    let aiMessage = HelpMessage(
                        content: response,
                        isFromUser: false,
                        timestamp: Date()
                    )
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = HelpMessage(
                        content: "I'm sorry, I'm having trouble responding right now. Please try again later or check your internet connection.",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

struct HelpChatMessageView: View {
    let message: HelpMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.vibPrimary)
                        )
                    
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.vibPrimary)
                            .padding(.top, 2)
                        
                        Text(message.content)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.vibText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.vibSurface.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                        .padding(.leading, 32)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TypingIndicatorView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.vibPrimary)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.vibTextSecondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.vibSurface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    HelpView()
} 