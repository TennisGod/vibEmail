import SwiftUI

struct AccountLinkingView: View {
    var onGoogleSignIn: () -> Void
    var onMicrosoftSignIn: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.vibBackground
                .ignoresSafeArea()
            
        VStack(spacing: 32) {
            Text("Link Your Email Account")
                .font(.title)
                    .foregroundColor(.vibText)
                .padding(.top, 40)

            Button(action: onGoogleSignIn) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Link Gmail")
                }
                .padding()
                    .background(Color.vibPrimary)
                    .foregroundColor(.vibBlack)
                .cornerRadius(8)
                    .shadow(color: .vibPrimary.opacity(0.3), radius: 5, x: 0, y: 2)
            }

            Button(action: onMicrosoftSignIn) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Link Outlook")
                }
                .padding()
                    .background(Color.vibSurface)
                    .foregroundColor(.vibText)
                .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.vibPrimary, lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
