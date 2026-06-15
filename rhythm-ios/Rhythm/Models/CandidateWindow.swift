//
//  CandidateWindow.swift
//  Rhythm
//
//  Candidate time windows for task scheduling
//

import Foundation

/// A candidate time window for scheduling a task
struct CandidateWindow: Codable, Identifiable {
    let id: String
    let label: String
    let gentleDescription: String
    let startTime: Date?
    let endTime: Date?
    let isCustom: Bool
    let isRecommended: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, label
        case gentleDescription = "gentle_description"
        case startTime = "start_time"
        case endTime = "end_time"
        case isCustom = "is_custom"
        case isRecommended = "is_recommended"
    }
}

// MARK: - Convenience Initializers

extension CandidateWindow {
    /// Create from ScheduleWindow (from VoiceIntent)
    init(from scheduleWindow: ScheduleWindow, id: String = UUID().uuidString, isRecommended: Bool = true) {
        self.id = id
        self.label = scheduleWindow.label
        self.gentleDescription = scheduleWindow.isFlexible ? "Flexible timing" : "Set time"
        self.startTime = scheduleWindow.start
        self.endTime = scheduleWindow.end
        self.isCustom = false
        self.isRecommended = isRecommended
    }
    
    /// Custom window placeholder
    static var custom: CandidateWindow {
        CandidateWindow(
            id: "custom",
            label: "Pick a time...",
            gentleDescription: "When works for you?",
            startTime: nil,
            endTime: nil,
            isCustom: true,
            isRecommended: false
        )
    }
}

// MARK: - Default Windows Generator

extension CandidateWindow {
    /// Generate contextual windows based on current time
    static func generateDefaultWindows() -> [CandidateWindow] {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        var windows: [CandidateWindow] = []
        
        // Morning window (if before noon)
        if hour < 12 {
            if let morning = AppConfig.morningWindow.calculateWindow() {
                windows.append(CandidateWindow(
                    id: "morning",
                    label: "This morning",
                    gentleDescription: "Get it done early",
                    startTime: morning.start,
                    endTime: morning.end,
                    isCustom: false,
                    isRecommended: true
                ))
            }
        }
        
        // Afternoon window (if before 5pm)
        if hour < 17 {
            if let afternoon = AppConfig.afternoonWindow.calculateWindow() {
                windows.append(CandidateWindow(
                    id: "afternoon",
                    label: "This afternoon",
                    gentleDescription: "After lunch energy",
                    startTime: afternoon.start,
                    endTime: afternoon.end,
                    isCustom: false,
                    isRecommended: hour >= 12
                ))
            }
        }
        
        // Evening window
        if let evening = AppConfig.eveningWindow.calculateWindow() {
            windows.append(CandidateWindow(
                id: "evening",
                label: "This evening",
                gentleDescription: "Wind-down time",
                startTime: evening.start,
                endTime: evening.end,
                isCustom: false,
                isRecommended: hour >= 17
            ))
        }
        
        // Tomorrow morning
        if let tomorrowMorning = calendar.date(byAdding: .day, value: 1, to: now),
           let morning = AppConfig.morningWindow.calculateWindow(from: tomorrowMorning) {
            windows.append(CandidateWindow(
                id: "tomorrow",
                label: "Tomorrow morning",
                gentleDescription: "Fresh start",
                startTime: morning.start,
                endTime: morning.end,
                isCustom: false,
                isRecommended: false
            ))
        }
        
        // Always add custom option
        windows.append(.custom)
        
        return windows
    }
}
