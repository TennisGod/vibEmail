import SwiftUI

struct ToneSelectionView: View {
    let action: EmailAction
    let email: Email
    @EnvironmentObject var emailViewModel: EmailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTone: EmailTone = .professional
    @State private var showingReplyForward = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.vibBackground
                    .ignoresSafeArea()
                
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Your Tone")
                        .font(.title2)
                        .fontWeight(.bold)
                            .foregroundColor(.vibText)
                    
                    Text("Select the tone for your \(action.rawValue.lowercased())")
                        .font(.subheadline)
                            .foregroundColor(.vibTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Tone options
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
                
                // Continue button
                Button(action: {
                    showingReplyForward = true
                }) {
                    Text("Continue")
                        .font(.headline)
                            .foregroundColor(.vibBlack)
                        .frame(maxWidth: .infinity)
                        .padding()
                            .background(Color.vibPrimary)
                        .cornerRadius(10)
                            .shadow(color: .vibPrimary.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.bottom)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingReplyForward) {
                ReplyForwardView(
                    action: action,
                    email: email,
                    selectedTone: selectedTone
                )
                .environmentObject(emailViewModel)
            }
        }
    }
}

struct ToneOptionView: View {
    let tone: EmailTone
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: toneIcon)
                    .font(.title)
                    .foregroundColor(isSelected ? .vibBlack : .vibPrimary)
                
                VStack(spacing: 4) {
                    Text(tone.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .vibBlack : .vibText)
                    
                    Text(tone.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .vibBlack.opacity(0.8) : .vibTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.vibPrimary : Color.vibSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.vibPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var toneIcon: String {
        switch tone {
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
}

#Preview {
    ToneSelectionView(
        action: .reply,
        email: Email(
            subject: "Test Email",
            sender: "Test Sender",
            senderEmail: "test@example.com",
            recipients: ["recipient@example.com"],
            content: "Test content",
            isArchived: false,
            messageId: "preview_message_2",
            threadId: "preview_thread_2"
        )
    )
    .environmentObject(EmailViewModel())
} 