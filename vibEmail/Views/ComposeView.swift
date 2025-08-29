import SwiftUI

struct ComposeView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var subject = ""
    @State private var recipients = ""
    @State private var content = ""
    @State private var selectedTone: EmailTone = .professional
    @State private var showingToneSelection = false
    @State private var showingSpeechInput = false
    @State private var isRecording = false
    @State private var selectedLanguage = "English"
    @State private var translatedContent = ""
    @State private var isTranslating = false
    @State private var showingAIAssistant = false
    @State private var aiPrompt = ""
    @State private var animateContent = false
    @State private var animateHeader = false
    @State private var focusedField: FocusedField? = nil
    
    enum FocusedField {
        case recipients, subject, content
    }
    
    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic"]
    
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
            
            NavigationView {
                VStack(spacing: 0) {
                    // Modern header with glass morphism
                    modernHeaderView
                    
                    // Email form with modern styling
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Recipients field with modern design
                            modernInputField(
                                title: "To",
                                placeholder: "Enter email addresses",
                                text: $recipients,
                                icon: "person.2.fill",
                                isMultiline: false
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.6).delay(0.1), value: animateContent)
                            
                            // Subject field with modern design
                            modernInputField(
                                title: "Subject",
                                placeholder: "What's this email about?",
                                text: $subject,
                                icon: "text.bubble.fill",
                                isMultiline: false
                            )
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeInOut(duration: 0.6).delay(0.2), value: animateContent)
                        
                            // Modern tone selection
                            modernToneSelector
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(.easeInOut(duration: 0.6).delay(0.3), value: animateContent)
                        
                            // Modern content area
                            modernContentArea
                                .opacity(animateContent ? 1.0 : 0.0)
                                .offset(y: animateContent ? 0 : 20)
                                .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateContent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showingToneSelection) {
                    ComposeToneSelectionView(selectedTone: $selectedTone)
                }
                .sheet(isPresented: $showingSpeechInput) {
                    SpeechInputView(content: $content, isRecording: $isRecording)
                }
                .sheet(isPresented: $showingAIAssistant) {
                    AIAssistantView(content: $content, prompt: $aiPrompt)
                }
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
        }
    }
    
    private var modernHeaderView: some View {
        HStack {
            // Modern back button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Cancel")
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
            
            // Modern title with icon
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .foregroundColor(.vibPrimary)
                Text("New Email")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.vibText)
            }
            
            Spacer()
            
            // Modern send button with glow effect
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                sendEmail()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Send")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.vibBlack)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        if canSend {
                            // Gradient background for active state
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.vibPrimary,
                                    Color.vibPrimary.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .shadow(color: .vibPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                        } else {
                            // Disabled state
                            Color.vibGrayMedium.opacity(0.6)
                        }
                    }
                )
                .cornerRadius(12)
                .scaleEffect(canSend ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            // Glass morphism header
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
    
    private var toneIcon: String {
        switch selectedTone {
        case .professional:
            return "briefcase.fill"
        case .friendly:
            return "heart.fill"
        case .casual:
            return "hand.wave.fill"
        case .formal:
            return "building.columns.fill"
        case .persuasive:
            return "megaphone.fill"
        case .apologetic:
            return "hand.raised.fill"
        case .enthusiastic:
            return "star.fill"
        case .urgent:
            return "exclamationmark.triangle.fill"
        case .humorous:
            return "face.smiling.fill"
        case .angry:
            return "flame.fill"
        case .original:
            return "doc.text.fill"
        }
    }
    
    private var canSend: Bool {
        !recipients.isEmpty && !subject.isEmpty && !content.isEmpty
    }
    
    // MARK: - Modern UI Components
    
    private func modernInputField(title: String, placeholder: String, text: Binding<String>, icon: String, isMultiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vibPrimary)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibText)
                
                Spacer()
            }
            
            ZStack(alignment: .topLeading) {
                // Background with glass morphism
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vibSurface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                if isMultiline {
                    TextEditor(text: text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibText)
                        .background(Color.clear)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: 120)
                } else {
                    TextField(placeholder, text: text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                }
                
                // Placeholder text for empty fields
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, isMultiline ? 12 : 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private var modernToneSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.vibPrimary)
                
                Text("Tone")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.vibText)
                
                Spacer()
                
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingToneSelection = true
                }) {
                    HStack(spacing: 6) {
                        Text("Change")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.vibPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.vibPrimary.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.vibPrimary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            
            // Tone display card
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(Color.vibPrimary.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: toneIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.vibPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedTone.rawValue)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.vibText)
                    
                    Text(selectedTone.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Visual indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.vibTextSecondary.opacity(0.6))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vibSurface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var modernContentArea: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with tools
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.vibPrimary)
                    
                    Text("Content")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.vibText)
                }
                
                Spacer()
                
                // Tool buttons
                HStack(spacing: 12) {
                    // Translation menu
                    Menu {
                        ForEach(languages, id: \.self) { language in
                            Button(action: {
                                selectedLanguage = language
                                if language != "English" {
                                    translateContent()
                                } else {
                                    translatedContent = content
                                }
                            }) {
                                HStack {
                                    Text(language)
                                    if selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.vibPrimary)
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.system(size: 12, weight: .semibold))
                            Text(selectedLanguage)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.vibPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.vibPrimary.opacity(0.1))
                        )
                    }
                }
            }
            
            // Action buttons row
            HStack(spacing: 12) {
                // Voice input button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingSpeechInput = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(isRecording ? "Stop Recording" : "Voice Input")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(isRecording ? .white : .vibSuccess)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isRecording ? Color.red : Color.vibSuccess.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isRecording ? Color.red : Color.vibSuccess.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // AI Assistant button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingAIAssistant = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .semibold))
                        Text("AI Assistant")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
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
                
                Spacer()
            }
            
            // Content text editor
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vibSurface.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vibPrimary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .frame(minHeight: 200)
                
                TextEditor(text: $content)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.vibText)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                
                if content.isEmpty {
                    Text("Compose your email here...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.vibTextSecondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private func translateContent() {
        guard selectedLanguage != "English" else { return }
        
        isTranslating = true
        
        Task {
            let translated = await emailViewModel.translateEmail(content, to: selectedLanguage)
            
            await MainActor.run {
                translatedContent = translated
                isTranslating = false
            }
        }
    }
    
    private func sendEmail() {
        let recipientList = recipients.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let emailContent = selectedLanguage == "English" ? content : translatedContent
        
        let draft = EmailDraft(
            subject: subject,
            recipients: recipientList,
            content: emailContent,
            tone: selectedTone
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

struct ComposeToneSelectionView: View {
    @Binding var selectedTone: EmailTone
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Your Tone")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(EmailTone.allCases, id: \.self) { tone in
                        ToneOptionView(
                            tone: tone,
                            isSelected: selectedTone == tone
                        ) {
                            selectedTone = tone
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.vibBlack)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.vibPrimary)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
}

struct AIAssistantView: View {
    @Binding var content: String
    @Binding var prompt: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("AI Email Assistant")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe what you want to say:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $prompt)
                        .font(.body)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                if isGenerating {
                    ProgressView("Generating email...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated Email:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $content)
                            .font(.body)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                    
                    Button("Generate") {
                        generateEmail()
                    }
                    .foregroundColor(.vibBlack)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.vibPrimary)
                    .cornerRadius(8)
                    .disabled(prompt.isEmpty || isGenerating)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func generateEmail() {
        isGenerating = true
        
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            content = "Based on your prompt: '\(prompt)', here is a professionally written email that conveys your message effectively."
            isGenerating = false
        }
    }
}

#Preview {
    ComposeView()
        .environmentObject(EmailViewModel())
} 