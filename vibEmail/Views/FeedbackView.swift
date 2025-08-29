import SwiftUI
import MessageUI

enum FeedbackCategory: String, CaseIterable {
    case bug = "Bug Report"
    case feature = "Feature Request"
    case improvement = "Improvement"
    case usability = "Usability Issue"
    case performance = "Performance"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .bug: return "ladybug.fill"
        case .feature: return "lightbulb.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .usability: return "person.fill.questionmark"
        case .performance: return "speedometer"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bug: return .red
        case .feature: return .blue
        case .improvement: return .green
        case .usability: return .orange
        case .performance: return .purple
        case .other: return .gray
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: FeedbackCategory = .other
    @State private var feedbackText = ""
    @State private var userEmail = ""
    @State private var rating = 5
    @State private var isSubmitting = false
    @State private var animateContent = false
    @State private var showSuccessMessage = false
    @State private var showingMailComposer = false
    @State private var showingMailError = false
    
    // Your feedback email address
    private let feedbackEmail = "feedback@vibemail.app"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color.vibBackground
                    .ignoresSafeArea()
                
                if showSuccessMessage {
                    successView
                } else {
                    feedbackForm
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.vibTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        submitFeedback()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canSubmit ? .vibPrimary : .vibTextSecondary)
                    .disabled(!canSubmit)
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(
                recipients: [feedbackEmail],
                subject: "vibEmail Feedback - \(selectedCategory.rawValue)",
                messageBody: createEmailBody(),
                isHTML: false
            ) { result in
                handleMailResult(result)
            }
        }
        .alert("Mail Not Available", isPresented: $showingMailError) {
            Button("OK") { }
        } message: {
            Text("Please configure Mail on your device or contact us at \(feedbackEmail)")
        }
    }
    
    private var feedbackForm: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Category Selection
                categorySection
                
                // Feedback Text
                textInputSection
                
                // Rating Section
                ratingSection
                
                // Contact Email (Optional)
                emailSection
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
    }
    

    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Rate your experience")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.vibText)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        rating = star
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundColor(star <= rating ? .vibPrimary : .vibTextSecondary.opacity(0.4))
                    }
                }
                
                Spacer()
                
                Text("\(rating)/5")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.vibTextSecondary)
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Feedback type")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.vibText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
        }
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Details")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.vibText)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $feedbackText)
                    .font(.system(size: 16))
                    .foregroundColor(.vibText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 100)
                
                if feedbackText.isEmpty {
                    Text("Describe your feedback...")
                        .font(.system(size: 16))
                        .foregroundColor(.vibTextSecondary.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.vibSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(feedbackText.isEmpty ? Color.vibTextSecondary.opacity(0.2) : Color.vibPrimary.opacity(0.4), lineWidth: 1)
                    )
            )
        }
    }
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Contact email (optional)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.vibText)
                
                Text("Only used for follow-up if needed")
                    .font(.system(size: 14))
                    .foregroundColor(.vibTextSecondary)
            }
            
            TextField("your@email.com", text: $userEmail)
                .font(.system(size: 16))
                .foregroundColor(.vibText)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.vibSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.vibTextSecondary.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    private var successView: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.vibSuccess)
                
                VStack(spacing: 12) {
                    Text("Feedback sent")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.vibText)
                    
                    Text("Thank you for helping us improve vibEmail")
                        .font(.system(size: 16))
                        .foregroundColor(.vibTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.vibPrimary)
                    )
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }
    
    private var canSubmit: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submitFeedback() {
        guard canSubmit else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            showingMailError = true
        }
    }
    
    private func createEmailBody() -> String {
        var body = ""
        
        body += "Rating: \(rating)/5 stars\n"
        body += "Category: \(selectedCategory.rawValue)\n\n"
        body += "Feedback:\n\(feedbackText)\n\n"
        
        if !userEmail.isEmpty {
            body += "Contact Email: \(userEmail)\n\n"
        }
        
        // Add device info for debugging
        body += "---\n"
        body += "Device Info:\n"
        body += "iOS Version: \(UIDevice.current.systemVersion)\n"
        body += "Device: \(UIDevice.current.model)\n"
        body += "App: vibEmail\n"
        
        return body
    }
    
    private func handleMailResult(_ result: MFMailComposeResult) {
        switch result {
        case .sent:
            withAnimation(.easeInOut(duration: 0.5)) {
                showSuccessMessage = true
            }
        case .cancelled, .failed, .saved:
            // Just dismiss, don't show error
            break
        @unknown default:
            break
        }
    }
}

struct CategoryButton: View {
    let category: FeedbackCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .vibPrimary : .vibTextSecondary)
                
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .vibText : .vibTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.vibSurface : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.vibPrimary.opacity(0.3) : Color.vibTextSecondary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    let isHTML: Bool
    let completion: (MFMailComposeResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: isHTML)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let completion: (MFMailComposeResult) -> Void
        
        init(completion: @escaping (MFMailComposeResult) -> Void) {
            self.completion = completion
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                self.completion(result)
            }
        }
    }
}

#Preview {
    FeedbackView()
} 