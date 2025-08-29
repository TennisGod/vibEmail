import Foundation
import AVFoundation
import Speech

class TextToSpeechService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var currentText = ""
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Speech Synthesis
    
    func speak(_ text: String, voice: String = "en-US", rate: Float = 0.5, pitch: Float = 1.0, volume: Float = 1.0) {
        guard !text.isEmpty else {
            errorMessage = "No text to speak"
            return
        }
        
        // Stop any current speech
        stopSpeaking()
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voice)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume
        
        // Store current utterance
        currentUtterance = utterance
        currentText = text
        
        // Start speaking
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
        errorMessage = nil
    }
    
    func speakEmail(_ email: Email, voice: String = "en-US") {
        let emailText = """
        From: \(email.sender)
        Subject: \(email.subject)
        Content: \(email.content)
        """
        
        speak(emailText, voice: voice)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
        currentText = ""
        currentUtterance = nil
    }
    
    func pauseSpeaking() {
        print("pauseSpeaking called - isSpeaking: \(isSpeaking)")
        if synthesizer.isSpeaking {
            print("Pausing synthesizer...")
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    func resumeSpeaking() {
        print("resumeSpeaking called - isPaused: \(isPaused)")
        if synthesizer.isPaused {
            print("Resuming synthesizer...")
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    // MARK: - Voice Management
    
    func getAvailableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices()
    }
    
    func getVoicesForLanguage(_ language: String) -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.starts(with: language)
        }
    }
    
    func getDefaultVoice(for language: String) -> AVSpeechSynthesisVoice? {
        return AVSpeechSynthesisVoice(language: language)
    }
    
    // MARK: - Speech Settings
    
    func setSpeechRate(_ rate: Float) {
        // Rate should be between 0.0 and 1.0
        let clampedRate = max(0.0, min(1.0, rate))
        
        // Update current utterance if it exists
        if let utterance = currentUtterance {
            utterance.rate = clampedRate
        }
        
        // If we're currently speaking, we need to restart with new rate
        if isSpeaking {
            let currentText = self.currentText
            stopSpeaking()
            speak(currentText, rate: clampedRate)
        }
    }
    
    func setSpeechPitch(_ pitch: Float) {
        // Pitch should be between 0.5 and 2.0
        let clampedPitch = max(0.5, min(2.0, pitch))
        if let utterance = currentUtterance {
            utterance.pitchMultiplier = clampedPitch
        }
    }
    
    func setSpeechVolume(_ volume: Float) {
        // Volume should be between 0.0 and 1.0
        let clampedVolume = max(0.0, min(1.0, volume))
        if let utterance = currentUtterance {
            utterance.volume = clampedVolume
        }
    }
    
    // MARK: - Text Processing
    
    func processTextForSpeech(_ text: String) -> String {
        var processedText = text
        
        // Remove email addresses and replace with "email address"
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        processedText = processedText.replacingOccurrences(of: emailPattern, with: "email address", options: .regularExpression)
        
        // Replace URLs with "link"
        let urlPattern = "https?://[^\\s]+"
        processedText = processedText.replacingOccurrences(of: urlPattern, with: "link", options: .regularExpression)
        
        // Replace common abbreviations
        let abbreviations: [String: String] = [
            "ASAP": "as soon as possible",
            "FYI": "for your information",
            "BTW": "by the way",
            "IMO": "in my opinion",
            "LOL": "laughing out loud",
            "OMG": "oh my god",
            "TIA": "thanks in advance",
            "RSVP": "please respond"
        ]
        
        for (abbreviation, fullForm) in abbreviations {
            processedText = processedText.replacingOccurrences(of: abbreviation, with: fullForm, options: .caseInsensitive)
        }
        
        return processedText
    }
    
    // MARK: - Language Support
    
    func detectLanguageAndSpeak(_ text: String) {
        // Simple language detection
        let language = detectLanguage(text)
        let voice = getDefaultVoice(for: language)?.language ?? "en-US"
        
        speak(text, voice: voice)
    }
    
    private func detectLanguage(_ text: String) -> String {
        // Simple language detection based on character sets
        let chineseRange = CharacterSet(charactersIn: "一-龯")
        let japaneseRange = CharacterSet(charactersIn: "あ-んア-ン")
        let koreanRange = CharacterSet(charactersIn: "가-힣")
        let arabicRange = CharacterSet(charactersIn: "ا-ي")
        
        if text.rangeOfCharacter(from: chineseRange) != nil {
            return "zh-CN"
        } else if text.rangeOfCharacter(from: japaneseRange) != nil {
            return "ja-JP"
        } else if text.rangeOfCharacter(from: koreanRange) != nil {
            return "ko-KR"
        } else if text.rangeOfCharacter(from: arabicRange) != nil {
            return "ar-SA"
        } else {
            return "en-US"
        }
    }
    
    // MARK: - Speech Control
    
    func skipToNextSentence() {
        // This would require more complex text analysis
        // For now, just stop and restart
        stopSpeaking()
    }
    
    func skipToPreviousSentence() {
        // This would require more complex text analysis
        // For now, just stop and restart
        stopSpeaking()
    }
    
    func adjustSpeed(_ speed: Float) {
        setSpeechRate(speed)
    }
    
    // MARK: - Error Handling
    
    private func handleSpeechError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Speech error: \(error.localizedDescription)"
            self.isSpeaking = false
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
            self.isPaused = false
            self.errorMessage = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentText = ""
            self.currentUtterance = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            print("Speech synthesizer did pause")
            self.isPaused = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            print("Speech synthesizer did continue")
            self.isPaused = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.currentText = ""
            self.currentUtterance = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // Update current speaking position
            let startIndex = utterance.speechString.index(utterance.speechString.startIndex, offsetBy: characterRange.location)
            let endIndex = utterance.speechString.index(startIndex, offsetBy: characterRange.length)
            self.currentText = String(utterance.speechString[startIndex..<endIndex])
        }
    }
} 