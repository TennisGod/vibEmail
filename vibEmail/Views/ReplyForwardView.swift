import SwiftUI

struct ReplyForwardView: View {
    let action: EmailAction
    let email: Email
    let selectedTone: EmailTone
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var aiGeneratedContent = ""
    @State private var editedContent = ""
    @State private var isGenerating = false
    @State private var showingTranslation = false
    @State private var selectedLanguage = "English"
    @State private var translatedContent = ""
    @State private var isTranslating = false
    @State private var showingSpeechInput = false
    @State private var isRecording = false
    
    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Split screen content
                VStack(spacing: 0) {
                    // Original email (top half)
                    originalEmailView
                    
                    Divider()
                    
                    // Response area (bottom half)
                    responseView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                generateAIContent()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(action.rawValue) - \(selectedTone.rawValue)")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: {
                // Send email
                sendEmail()
            }) {
                Text("Send")
                    .font(.headline)
                    .foregroundColor(.vibBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.vibPrimary)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.vibBackground)
    }
    
    private var originalEmailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Original Email")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                                        PriorityTagView(
                            priority: email.priority,
                            isAnalyzing: emailViewModel.analyzingEmails.contains(email.id)
                        )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("From: \(email.sender)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Subject: \(email.subject)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(email.content)
                    .font(.body)
                    .lineSpacing(4)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background(Color.vibSurface)
    }
    
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Response")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Translation dropdown
                Menu {
                    ForEach(languages, id: \.self) { language in
                        Button(action: {
                            selectedLanguage = language
                            if language != "English" {
                                translateContent()
                            } else {
                                translatedContent = editedContent
                            }
                        }) {
                            HStack {
                                Text(language)
                                if selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text(selectedLanguage)
                    }
                    .font(.caption)
                    .foregroundColor(.vibPrimary)
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    generateAIContent()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .font(.caption)
                    .foregroundColor(.vibPrimary)
                }
                .disabled(isGenerating)
                
                Button(action: {
                    showingSpeechInput = true
                }) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        Text(isRecording ? "Stop" : "Voice")
                    }
                    .font(.caption)
                    .foregroundColor(isRecording ? .vibError : .vibSuccess)
                }
                
                Spacer()
            }
            
            // Content area
            if isGenerating {
                VStack {
                    ProgressView("Generating AI response...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                TextEditor(text: $editedContent)
                    .font(.body)
                    .lineSpacing(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background(Color.vibBackground)
        .sheet(isPresented: $showingSpeechInput) {
            SpeechInputView(content: $editedContent, isRecording: $isRecording)
        }
    }
    
    private func generateAIContent() {
        isGenerating = true
        
        Task {
            let generatedContent: String
            if action == .reply {
                generatedContent = await emailViewModel.generateAIReply(for: email, tone: selectedTone)
            } else {
                generatedContent = await emailViewModel.generateAIForward(for: email, tone: selectedTone)
            }
            
            await MainActor.run {
                aiGeneratedContent = generatedContent
                editedContent = generatedContent
                isGenerating = false
            }
        }
    }
    
    private func translateContent() {
        guard selectedLanguage != "English" else { return }
        
        isTranslating = true
        
        Task {
            let translated = await emailViewModel.translateEmail(editedContent, to: selectedLanguage)
            
            await MainActor.run {
                translatedContent = translated
                isTranslating = false
            }
        }
    }
    
    private func sendEmail() {
        let draft = EmailDraft(
            subject: action == .reply ? "Re: \(email.subject)" : "Fwd: \(email.subject)",
            recipients: action == .reply ? [email.senderEmail] : [],
            content: selectedLanguage == "English" ? editedContent : translatedContent,
            tone: selectedTone,
            isReply: action == .reply,
            originalEmailId: email.id
        )
        
        Task {
            let success = await emailViewModel.sendEmail(draft)
            await MainActor.run {
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct SpeechInputView: View {
    @Binding var content: String
    @Binding var isRecording: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var transcribedText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(isRecording ? .vibError : .vibPrimary)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                    
                    Text(isRecording ? "Listening..." : "Tap to start recording")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    if !transcribedText.isEmpty {
                        Text(transcribedText)
                            .font(.body)
                            .padding()
                            .background(Color.vibSurface)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                    
                    Button(isRecording ? "Stop" : "Start") {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(isRecording ? Color.vibError : Color.vibPrimary)
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func startRecording() {
        isRecording = true
        transcribedText = ""
        // Start speech recognition
    }
    
    private func stopRecording() {
        isRecording = false
        content = transcribedText
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ReplyForwardView(
        action: .reply,
        email: Email(
            subject: "Test Email",
            sender: "Test Sender",
            senderEmail: "test@example.com",
            recipients: ["recipient@example.com"],
            content: "Test content",
            isArchived: false,
            messageId: "preview_message_3",
            threadId: "preview_thread_3"
        ),
        selectedTone: .professional
    )
    .environmentObject(EmailViewModel())
} 