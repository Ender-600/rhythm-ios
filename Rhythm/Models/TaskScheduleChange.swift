//
//  TaskScheduleChange.swift
//  Rhythm
//
//  Logs every snooze/reschedule for future learning
//  Every change is preserved - we never shame, always learn
//

import Foundation
import SwiftData

@Model
final class TaskScheduleChange {
    // MARK: - Core Fields
    
    var id: UUID
    var changeType: ChangeType
    var changedAt: Date
    
    // MARK: - Schedule Details
    
    var previousWindowStart: Date?
    var previousWindowEnd: Date?
    var newWindowStart: Date?
    var newWindowEnd: Date?
    
    // MARK: - Context
    
    var reason: String? // User-provided or system-inferred reason
    var snoozeOption: String? // Which preset was used
    var wasUserInitiated: Bool // vs system-suggested
    
    // MARK: - Sync Fields
    
    var serverId: String?
    var dirtyFlag: Bool
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    @Relationship(inverse: \RhythmTask.scheduleChanges)
    var task: RhythmTask?
    
    // MARK: - Initialization
    
    init(
        changeType: ChangeType,
        previousWindowStart: Date?,
        previousWindowEnd: Date?,
        newWindowStart: Date?,
        newWindowEnd: Date?,
        reason: String? = nil,
        snoozeOption: SnoozeOption? = nil,
        wasUserInitiated: Bool = true
    ) {
        self.id = UUID()
        self.changeType = changeType
        self.changedAt = Date()
        self.previousWindowStart = previousWindowStart
        self.previousWindowEnd = previousWindowEnd
        self.newWindowStart = newWindowStart
        self.newWindowEnd = newWindowEnd
        self.reason = reason
        self.snoozeOption = snoozeOption?.rawValue
        self.wasUserInitiated = wasUserInitiated
        self.serverId = nil
        self.dirtyFlag = true
        self.lastSyncedAt = nil
    }
    
    // MARK: - Change Types
    
    enum ChangeType: String, Codable {
        case snoozed = "snoozed"
        case rescheduled = "rescheduled"
        case windowExpanded = "window_expanded"
        case windowShortened = "window_shortened"
        case cancelled = "cancelled"
        case restored = "restored" // Undo
    }
}

// MARK: - Convenience Extensions

extension TaskScheduleChange {
    /// Human-readable summary of the change
    var summary: String {
        switch changeType {
        case .snoozed:
            if let snooze = snoozeOption {
                return "Snoozed: \(snooze)"
            }
            return "Snoozed"
        case .rescheduled:
            return "Rescheduled"
        case .windowExpanded:
            return "Extended time window"
        case .windowShortened:
            return "Shortened time window"
        case .cancelled:
            return "Removed from schedule"
        case .restored:
            return "Restored to schedule"
        }
    }
    
    /// Gentle, non-judgmental description
    var gentleDescription: String {
        switch changeType {
        case .snoozed:
            return "Moved to a better time"
        case .rescheduled:
            return "Found a new slot"
        case .windowExpanded:
            return "More breathing room"
        case .windowShortened:
            return "Tightened up the window"
        case .cancelled:
            return "Cleared from the plan"
        case .restored:
            return "Back on the radar"
        }
    }
    
    /// Mark as synced
    func markSynced(serverId: String) {
        self.serverId = serverId
        self.dirtyFlag = false
        self.lastSyncedAt = Date()
    }
}

