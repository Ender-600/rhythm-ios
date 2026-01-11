//
//  AppConfig.swift
//  Rhythm
//
//  Central configuration for the app
//

import Foundation

enum AppConfig {
    // MARK: - Backend Configuration
    
    /// Base URL for the FastAPI backend
    static var apiBaseURL: URL {
        if let urlString = ProcessInfo.processInfo.environment["RHYTHM_API_URL"],
           let url = URL(string: urlString) {
            return url
        }
        // Default to localhost for development
        return URL(string: "http://localhost:8000")!
    }
    
    /// API timeout in seconds
    static let apiTimeout: TimeInterval = 30
    
    /// Whether to use mock responses when offline
    static let useMockWhenOffline = true
    
    // MARK: - LLM Configuration
    
    /// OpenAI API Key (from environment or hardcoded for dev)
    static var openAIAPIKey: String {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    /// OpenAI Base URL
    static var openAIBaseURL: URL {
        if let urlString = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"],
           let url = URL(string: urlString) {
            return url
        }
        return URL(string: "https://api.openai.com/v1")!
    }
    
    /// LLM model to use
    static var llmModel: String {
        ProcessInfo.processInfo.environment["LLM_MODEL"] ?? "gpt-4o-mini"
    }
    
    /// Whether to use LLM for intent parsing (vs fallback local parsing)
    static var useLLMForIntentParsing: Bool {
        !openAIAPIKey.isEmpty
    }
    
    // MARK: - Voice Configuration
    
    /// Minimum press duration to start recording (seconds)
    static let pressAndHoldThreshold: TimeInterval = 0.3
    
    /// Maximum recording duration (seconds)
    static let maxRecordingDuration: TimeInterval = 60
    
    /// Speech recognition locale
    static var speechLocale: Locale {
        Locale.current
    }
    
    // MARK: - Time Window Defaults
    
    /// Default morning time (hour)
    static let defaultMorningHour = 9
    
    /// Default evening time (hour)
    static let defaultEveningHour = 19
    
    /// Default "tonight" start hour
    static let tonightStartHour = 19
    
    /// Default "tonight" end hour
    static let tonightEndHour = 22
    
    /// Default buffer minutes before/after windows
    static let defaultBufferMinutes = 15
    
    // MARK: - Notification Configuration
    
    /// Default morning preview notification hour
    static let morningPreviewHour = 8
    
    /// Default morning preview notification minute
    static let morningPreviewMinute = 0
    
    /// Minutes before window start to send reminder
    static let windowReminderMinutesBefore = 5
    
    // MARK: - Sync Configuration
    
    /// How often to attempt sync (seconds)
    static let syncInterval: TimeInterval = 300 // 5 minutes
    
    /// Maximum events to batch upload at once
    static let maxEventBatchSize = 100
    
    // MARK: - Feature Flags
    
    /// Enable voice input (requires permissions)
    static let voiceInputEnabled = true
    
    /// Enable notifications
    static let notificationsEnabled = true
    
    /// Enable offline mode
    static let offlineModeEnabled = true
    
    /// Show debug info in UI
    #if DEBUG
    static let showDebugInfo = true
    #else
    static let showDebugInfo = false
    #endif
}

// MARK: - Time Window Presets

extension AppConfig {
    struct TimeWindowPreset {
        let name: String
        let gentleLabel: String
        let startHour: Int
        let startMinute: Int
        let endHour: Int
        let endMinute: Int
        let isRelativeToNow: Bool
        
        func calculateWindow(from date: Date = Date()) -> (start: Date, end: Date)? {
            let calendar = Calendar.current
            
            if isRelativeToNow {
                // Relative windows start from now
                var startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                startComponents.hour = startHour
                startComponents.minute = startMinute
                
                guard var start = calendar.date(from: startComponents) else { return nil }
                
                // If start time has passed, move to tomorrow
                if start < date {
                    start = calendar.date(byAdding: .day, value: 1, to: start) ?? start
                }
                
                var endComponents = calendar.dateComponents([.year, .month, .day], from: start)
                endComponents.hour = endHour
                endComponents.minute = endMinute
                
                guard let end = calendar.date(from: endComponents) else { return nil }
                
                return (start, end)
            } else {
                // Absolute windows use specific times
                var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
                startComponents.hour = startHour
                startComponents.minute = startMinute
                
                var endComponents = startComponents
                endComponents.hour = endHour
                endComponents.minute = endMinute
                
                guard let start = calendar.date(from: startComponents),
                      let end = calendar.date(from: endComponents) else { return nil }
                
                return (start, end)
            }
        }
    }
    
    static let morningWindow = TimeWindowPreset(
        name: "Morning",
        gentleLabel: "Start fresh in the morning",
        startHour: 9,
        startMinute: 0,
        endHour: 12,
        endMinute: 0,
        isRelativeToNow: true
    )
    
    static let afternoonWindow = TimeWindowPreset(
        name: "Afternoon",
        gentleLabel: "After lunch energy",
        startHour: 13,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        isRelativeToNow: true
    )
    
    static let eveningWindow = TimeWindowPreset(
        name: "Evening",
        gentleLabel: "Wind-down time",
        startHour: 19,
        startMinute: 0,
        endHour: 22,
        endMinute: 0,
        isRelativeToNow: true
    )
}

