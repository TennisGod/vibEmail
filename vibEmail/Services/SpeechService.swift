import Foundation
import Speech
import AVFoundation

class SpeechService: NSObject, ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        setupSpeechRecognition()
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.errorMessage = nil
                case .denied:
                    self?.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self?.errorMessage = "Speech recognition restricted on this device"
                case .notDetermined:
                    self?.errorMessage = "Speech recognition not yet authorized"
                @unknown default:
                    self?.errorMessage = "Speech recognition authorization unknown"
                }
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Reset state
        transcribedText = ""
        errorMessage = nil
        
        // Check authorization
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        // Check if speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Failed to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self?.stopRecording()
                    return
                }
                
                if let result = result {
                    self?.transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.stopRecording()
                    }
                }
            }
        }
        
        isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // End recognition request
        recognitionRequest?.endAudio()
        
        // Cancel recognition task
        recognitionTask?.cancel()
        
        // Reset state
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func pauseRecording() {
        guard isRecording else { return }
        
        audioEngine.pause()
    }
    
    func resumeRecording() {
        guard isRecording else { return }
        
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to resume recording: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Language Support
    
    func setLanguage(_ languageCode: String) {
        guard let newRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode)) else {
            errorMessage = "Language not supported: \(languageCode)"
            return
        }
        
        speechRecognizer?.delegate = nil
        speechRecognizer = newRecognizer
        speechRecognizer?.delegate = self
    }
    
    func getSupportedLanguages() -> [String] {
        return SFSpeechRecognizer.supportedLocales().map { $0.identifier }
    }
    
    // MARK: - Text Processing
    
    func processTranscribedText(_ text: String) -> String {
        // Clean up transcribed text
        var processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add punctuation if missing
        if !processedText.isEmpty && !processedText.hasSuffix(".") && !processedText.hasSuffix("!") && !processedText.hasSuffix("?") {
            processedText += "."
        }
        
        // Capitalize first letter
        if !processedText.isEmpty {
            processedText = processedText.prefix(1).uppercased() + processedText.dropFirst()
        }
        
        return processedText
    }
    
    // MARK: - Email Intent Detection
    
    func detectEmailIntent(_ text: String) -> EmailIntent {
        let lowercasedText = text.lowercased()
        
        if lowercasedText.contains("reply") || lowercasedText.contains("respond") {
            return .reply
        } else if lowercasedText.contains("forward") || lowercasedText.contains("share") {
            return .forward
        } else if lowercasedText.contains("compose") || lowercasedText.contains("write") || lowercasedText.contains("send") {
            return .compose
        } else {
            return .content
        }
    }
    
    enum EmailIntent {
        case reply
        case forward
        case compose
        case content
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "Speech recognition became unavailable"
                self.stopRecording()
            }
        }
    }
} 
