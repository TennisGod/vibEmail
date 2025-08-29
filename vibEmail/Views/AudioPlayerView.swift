import SwiftUI

struct AudioPlayerView: View {
    @EnvironmentObject var emailViewModel: EmailViewModel
    @State private var isExpanded = false
    @State private var selectedSpeed: Float = 1.0 // UI: 0.5x, 1x, 1.5x; default to 1x
    
    @ObservedObject var textToSpeechService: TextToSpeechService
    
    private func mappedRate(for uiSpeed: Float) -> Float {
        switch uiSpeed {
        case 0.5: return 0.35
        case 1.0: return 0.5
        case 1.5: return 0.65
        default: return 0.5
        }
    }
    
    private func restartCurrentEmailIfNeeded(newSpeed: Float) {
        // Only restart if currently reading
        if let id = emailViewModel.currentlyReadEmailID,
           let email = emailViewModel.emails.first(where: { $0.id == id }),
           textToSpeechService.isSpeaking || textToSpeechService.isPaused {
            let fullText = email.content
            let currentChunk = textToSpeechService.currentText
            var startIndex = fullText.startIndex
            if let range = fullText.range(of: currentChunk, options: String.CompareOptions.caseInsensitive) {
                startIndex = range.lowerBound
            }
            let remainingText = String(fullText[startIndex...])
            textToSpeechService.stopSpeaking()
            textToSpeechService.speak(remainingText, rate: mappedRate(for: newSpeed))
        }
    }
    
    private func skipInCurrentEmail(seconds: Double) {
        guard let id = emailViewModel.currentlyReadEmailID,
              let email = emailViewModel.emails.first(where: { $0.id == id }),
              textToSpeechService.isSpeaking || textToSpeechService.isPaused else { return }
        let fullText = email.content
        let currentChunk = textToSpeechService.currentText
        // Estimate current position
        let currentPos = fullText.range(of: currentChunk, options: String.CompareOptions.caseInsensitive)?.lowerBound ?? fullText.startIndex
        let charsPerSecond: Double
        switch selectedSpeed {
        case 0.5: charsPerSecond = 7.0
        case 1.0: charsPerSecond = 13.0
        case 1.5: charsPerSecond = 18.0
        default: charsPerSecond = 13.0
        }
        let charOffset = Int(charsPerSecond * seconds)
        let currentIndex = fullText.distance(from: fullText.startIndex, to: currentPos)
        var newIndex = currentIndex + charOffset
        newIndex = max(0, min(fullText.count - 1, newIndex))
        let startIdx = fullText.index(fullText.startIndex, offsetBy: newIndex)
        let remainingText = String(fullText[startIdx...])
        textToSpeechService.stopSpeaking()
        textToSpeechService.speak(remainingText, rate: mappedRate(for: selectedSpeed))
    }
    
    init(textToSpeechService: TextToSpeechService) {
        self.textToSpeechService = textToSpeechService
    }
    
    var body: some View {
        let currentEmailSubject: String? = {
            if let id = emailViewModel.currentlyReadEmailID {
                return emailViewModel.emails.first(where: { $0.id == id })?.subject
            }
            return nil
        }()
        VStack {
            if textToSpeechService.isSpeaking || textToSpeechService.isPaused {
                VStack(spacing: 0) {
                    // Main player bar
                    HStack(spacing: 12) {
                        // Play/Pause button
                        Button(action: {
                            if textToSpeechService.isPaused {
                                textToSpeechService.resumeSpeaking()
                            } else if textToSpeechService.isSpeaking {
                                textToSpeechService.pauseSpeaking()
                            }
                        }) {
                            Image(systemName: textToSpeechService.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.title2)
                                .foregroundColor(.vibPrimary)
                        }
                        
                        // Current email subject
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reading Email")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.vibText)
                            
                            Text(currentEmailSubject ?? "")
                                .font(.caption2)
                                .foregroundColor(.vibTextSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        Spacer()
                        
                        // Speed control
                        Button(action: {
                            // Cycle through speeds
                            if selectedSpeed == 0.5 {
                                selectedSpeed = 1.0
                            } else if selectedSpeed == 1.0 {
                                selectedSpeed = 1.5
                            } else {
                                selectedSpeed = 0.5
                            }
                            emailViewModel.playbackSpeed = selectedSpeed
                            restartCurrentEmailIfNeeded(newSpeed: selectedSpeed)
                        }) {
                            Text("\(selectedSpeed, specifier: "%.1fx")")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.vibPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.vibPrimary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // Close button (X)
                        Button(action: {
                            textToSpeechService.stopSpeaking()
                            emailViewModel.currentlyReadEmailID = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.vibError)
                        }
                        
                        // Expand/Collapse button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                                .font(.caption)
                                .foregroundColor(.vibTextSecondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.vibSurface)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Expanded controls
                    if isExpanded {
                        VStack(spacing: 12) {
                            // Progress indicator
                            ProgressView()
                                .progressViewStyle(LinearProgressViewStyle(tint: .vibPrimary))
                                .scaleEffect(y: 0.5)
                            
                            // Additional controls
                            HStack(spacing: 20) {
                                // Skip backward
                                Button(action: {
                                    skipInCurrentEmail(seconds: -5)
                                }) {
                                    Image(systemName: "gobackward.5")
                                        .font(.title3)
                                        .foregroundColor(.vibTextSecondary)
                                }
                                
                                // Skip forward
                                Button(action: {
                                    skipInCurrentEmail(seconds: 5)
                                }) {
                                    Image(systemName: "goforward.5")
                                        .font(.title3)
                                        .foregroundColor(.vibTextSecondary)
                                }
                                
                                // Speed control buttons
                                VStack(spacing: 4) {
                                    Text("Speed")
                                        .font(.caption2)
                                        .foregroundColor(.vibTextSecondary)
                                    
                                    HStack(spacing: 8) {
                                        Button("0.5x") {
                                            selectedSpeed = 0.5
                                            emailViewModel.playbackSpeed = selectedSpeed
                                            restartCurrentEmailIfNeeded(newSpeed: selectedSpeed)
                                        }
                                        .font(.caption2)
                                        .foregroundColor(selectedSpeed == 0.5 ? .vibPrimary : .vibTextSecondary)
                                        
                                        Button("1x") {
                                            selectedSpeed = 1.0
                                            emailViewModel.playbackSpeed = selectedSpeed
                                            restartCurrentEmailIfNeeded(newSpeed: selectedSpeed)
                                        }
                                        .font(.caption2)
                                        .foregroundColor(selectedSpeed == 1.0 ? .vibPrimary : .vibTextSecondary)
                                        
                                        Button("1.5x") {
                                            selectedSpeed = 1.5
                                            emailViewModel.playbackSpeed = selectedSpeed
                                            restartCurrentEmailIfNeeded(newSpeed: selectedSpeed)
                                        }
                                        .font(.caption2)
                                        .foregroundColor(selectedSpeed == 1.5 ? .vibPrimary : .vibTextSecondary)
                                    }
                                }
                                
                                // Voice settings (placeholder)
                                Button(action: {
                                    // Show voice selection - placeholder for now
                                }) {
                                    Image(systemName: "person.wave.2")
                                        .font(.title3)
                                        .foregroundColor(.vibTextSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .background(Color.vibSurface)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            selectedSpeed = emailViewModel.playbackSpeed
        }
        .animation(.easeInOut(duration: 0.3), value: textToSpeechService.isSpeaking)
        .animation(.easeInOut(duration: 0.3), value: textToSpeechService.isPaused)
        .animation(.easeInOut(duration: 0.3), value: textToSpeechService.currentText)
    }
} 
