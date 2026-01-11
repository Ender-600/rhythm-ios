//
//  SpeechService.swift
//  Rhythm
//
//  Voice input service using Speech framework
//  Supports tap-to-record and press-and-hold modes
//

import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechService: @unchecked Sendable {
    // MARK: - Published State
    
    private(set) var isRecording = false
    private(set) var transcript = ""
    private(set) var partialTranscript = ""
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var error: SpeechError?
    private(set) var permissionStatus: PermissionStatus = .unknown
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var recordingStartTime: Date?
    private var durationTimer: Timer?
    
    // MARK: - Types
    
    enum PermissionStatus {
        case unknown
        case authorized
        case denied
        case restricted
        case notDetermined
        
        var canRecord: Bool {
            self == .authorized
        }
        
        var friendlyMessage: String {
            switch self {
            case .unknown:
                return "Checking permissions..."
            case .authorized:
                return "Ready to listen"
            case .denied:
                return "Voice input needs your permission. You can enable it in Settings."
            case .restricted:
                return "Voice input isn't available on this device."
            case .notDetermined:
                return "Tap to allow voice input"
            }
        }
    }
    
    enum SpeechError: LocalizedError {
        case noPermission
        case recognizerUnavailable
        case audioSessionFailed(String)
        case recordingFailed(String)
        case recognitionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .noPermission:
                return "Voice input needs permission to work."
            case .recognizerUnavailable:
                return "Speech recognition isn't available right now. Please try again."
            case .audioSessionFailed(let detail):
                return "Couldn't set up audio: \(detail)"
            case .recordingFailed(let detail):
                return "Recording issue: \(detail)"
            case .recognitionFailed(let detail):
                return "Couldn't understand that: \(detail)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .noPermission:
                return "Open Settings to enable microphone and speech recognition access."
            case .recognizerUnavailable:
                return "Check your internet connection and try again."
            case .audioSessionFailed, .recordingFailed:
                return "Make sure no other app is using the microphone."
            case .recognitionFailed:
                return "Try speaking more clearly, or tap to try again."
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupRecognizer()
    }
    
    private func setupRecognizer() {
        let locale = AppConfig.speechLocale
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        // Check initial status
        Task { @MainActor in
            await checkPermissions()
        }
    }
    
    // MARK: - Permissions
    
    @MainActor
    func checkPermissions() async {
        // Check speech recognition
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch speechStatus {
        case .authorized:
            // Also check microphone
            let micStatus = AVAudioApplication.shared.recordPermission
            switch micStatus {
            case .granted:
                permissionStatus = .authorized
            case .denied:
                permissionStatus = .denied
            case .undetermined:
                permissionStatus = .notDetermined
            @unknown default:
                permissionStatus = .unknown
            }
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .restricted
        case .notDetermined:
            permissionStatus = .notDetermined
        @unknown default:
            permissionStatus = .unknown
        }
    }
    
    @MainActor
    func requestPermissions() async -> Bool {
        // Request speech recognition
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        
        guard speechGranted else {
            permissionStatus = .denied
            return false
        }
        
        // Request microphone
        let micGranted = await AVAudioApplication.requestRecordPermission()
        
        if micGranted {
            permissionStatus = .authorized
            return true
        } else {
            permissionStatus = .denied
            return false
        }
    }
    
    // MARK: - Recording Control
    
    @MainActor
    func startRecording() async {
        // Check and request permission if needed
        if !permissionStatus.canRecord {
            if permissionStatus == .notDetermined {
                _ = await requestPermissions()
            }
            guard permissionStatus.canRecord else {
                error = .noPermission
                return
            }
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            error = .recognizerUnavailable
            return
        }
        
        // Clear previous state
        error = nil
        transcript = ""
        partialTranscript = ""
        recordingDuration = 0
        
        do {
            try await setupAudioSession()
            try startAudioEngine()
            isRecording = true
            recordingStartTime = Date()
            startDurationTimer()
        } catch let err as SpeechError {
            error = err
        } catch {
            self.error = .recordingFailed(error.localizedDescription)
        }
    }
    
    @MainActor
    func stopRecording() {
        stopDurationTimer()
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        // Calculate final duration
        if let start = recordingStartTime {
            recordingDuration = Date().timeIntervalSince(start)
        }
        
        // Finalize transcript
        if !partialTranscript.isEmpty {
            transcript = partialTranscript
        }
        
        isRecording = false
        recordingStartTime = nil
        
        // Clean up
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    @MainActor
    func cancelRecording() {
        stopDurationTimer()
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        
        transcript = ""
        partialTranscript = ""
        recordingDuration = 0
        isRecording = false
        recordingStartTime = nil
        
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // MARK: - Private Helpers
    
    private func setupAudioSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    private func startAudioEngine() throws {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw SpeechError.recordingFailed("Couldn't create audio engine")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recordingFailed("Couldn't create recognition request")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            throw SpeechError.recordingFailed(error.localizedDescription)
        }
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.partialTranscript = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.transcript = result.bestTranscription.formattedString
                    }
                }
                
                if let error = error {
                    // Don't report cancellation errors
                    let nsError = error as NSError
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        self?.error = .recognitionFailed(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if let start = self?.recordingStartTime {
                    self?.recordingDuration = Date().timeIntervalSince(start)
                    
                    // Auto-stop at max duration
                    if let duration = self?.recordingDuration, duration >= AppConfig.maxRecordingDuration {
                        self?.stopRecording()
                    }
                }
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}

// MARK: - Convenience Extensions

extension SpeechService {
    /// Current transcript (partial or final)
    var currentTranscript: String {
        transcript.isEmpty ? partialTranscript : transcript
    }
    
    /// Whether there's any transcript content
    var hasTranscript: Bool {
        !currentTranscript.isEmpty
    }
    
    /// Formatted recording duration
    var formattedDuration: String {
        let seconds = Int(recordingDuration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

