//
//  RhythmTask.swift
//  Rhythm
//
//  Core task entity - the heart of the app
//  Named RhythmTask to avoid conflict with Swift's Task type
//

import Foundation
import SwiftData

@Model
final class RhythmTask {
    // MARK: - Core Identity
    
    var id: UUID
    var title: String
    var utteranceText: String? // Original speech, preserved
    var createdAt: Date
    
    // MARK: - Time Window (flexible, not rigid deadlines)
    
    var windowStart: Date?
    var windowEnd: Date?
    var deadline: Date? // Hard deadline if specified
    var bufferMinutes: Int // Extra time before/after
    
    // MARK: - Status & Priority
    
    var statusRaw: String // TaskStatus raw value
    var priorityRaw: String // TaskPriority raw value
    
    // MARK: - Lifecycle Timestamps
    
    var openedAt: Date? // When user first started
    var pausedAt: Date? // Last pause time
    var completedAt: Date?
    var skippedAt: Date?
    
    // MARK: - Duration Tracking
    
    var estimatedMinutes: Int?
    var actualMinutes: Int? // User-adjusted after completion
    var totalActiveSeconds: Double // Accumulated active time
    
    // MARK: - Snooze Tracking (no shame!)
    
    var snoozeCount: Int
    var lastSnoozedAt: Date?
    
    // MARK: - Plan Sketch
    
    var openingAction: String? // Suggested first step
    var notes: String?
    
    // MARK: - Sync Fields
    
    var serverId: String?
    var dirtyFlag: Bool
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    var utterance: Utterance?
    
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]?
    
    @Relationship(deleteRule: .cascade)
    var scheduleChanges: [TaskScheduleChange]?
    
    // MARK: - Computed Properties
    
    var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }
    
    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .normal }
        set { priorityRaw = newValue.rawValue }
    }
    
    // MARK: - Initialization
    
    init(
        title: String,
        utteranceText: String? = nil,
        windowStart: Date? = nil,
        windowEnd: Date? = nil,
        priority: TaskPriority = .normal,
        openingAction: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.utteranceText = utteranceText
        self.createdAt = Date()
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.bufferMinutes = 15 // Default 15-minute buffer
        self.statusRaw = TaskStatus.notStarted.rawValue
        self.priorityRaw = priority.rawValue
        self.snoozeCount = 0
        self.totalActiveSeconds = 0
        self.openingAction = openingAction
        self.serverId = nil
        self.dirtyFlag = true
        self.lastSyncedAt = nil
        self.tags = []
        self.scheduleChanges = []
    }
}

// MARK: - Lifecycle Actions

extension RhythmTask {
    /// Start working on the task
    func start() {
        guard status != .inProgress else { return }
        
        if openedAt == nil {
            openedAt = Date()
        }
        pausedAt = nil
        status = .inProgress
        markDirty()
    }
    
    /// Pause the task
    func pause() {
        guard status == .inProgress else { return }
        
        // Accumulate active time
        if let opened = openedAt, pausedAt == nil {
            let elapsed = Date().timeIntervalSince(opened)
            totalActiveSeconds += elapsed
        }
        
        pausedAt = Date()
        markDirty()
    }
    
    /// Resume from pause
    func resume() {
        guard status == .inProgress, pausedAt != nil else { return }
        pausedAt = nil
        openedAt = Date() // Reset for new active period
        markDirty()
    }
    
    /// Mark as complete
    func complete(actualMinutes: Int? = nil) {
        // Finalize active time
        if status == .inProgress, pausedAt == nil, let opened = openedAt {
            totalActiveSeconds += Date().timeIntervalSince(opened)
        }
        
        status = .done
        completedAt = Date()
        self.actualMinutes = actualMinutes ?? Int(totalActiveSeconds / 60)
        markDirty()
    }
    
    /// Skip the task (no shame)
    func skip() {
        status = .done
        skippedAt = Date()
        markDirty()
    }
    
    /// Snooze to a new time
    func snooze(
        to newStart: Date?,
        newEnd: Date? = nil,
        option: SnoozeOption? = nil,
        reason: String? = nil
    ) {
        // Record the change
        let change = TaskScheduleChange(
            changeType: .snoozed,
            previousWindowStart: windowStart,
            previousWindowEnd: windowEnd,
            newWindowStart: newStart,
            newWindowEnd: newEnd,
            reason: reason,
            snoozeOption: option,
            wasUserInitiated: true
        )
        scheduleChanges?.append(change)
        
        // Update window
        windowStart = newStart
        if let end = newEnd {
            windowEnd = end
        } else if let start = newStart, let duration = windowDuration {
            windowEnd = start.addingTimeInterval(duration)
        }
        
        snoozeCount += 1
        lastSnoozedAt = Date()
        markDirty()
    }
    
    /// Snooze by a predefined option
    func snooze(for option: SnoozeOption) {
        let newStart = option.calculateNewTime()
        snooze(to: newStart, option: option)
    }
    
    /// Snooze until a specific time
    func snoozeUntil(_ date: Date) {
        snooze(to: date, option: .custom(Int(date.timeIntervalSinceNow / 60)))
    }
}

// MARK: - Time Window Helpers

extension RhythmTask {
    /// Duration of the time window
    var windowDuration: TimeInterval? {
        guard let start = windowStart, let end = windowEnd else { return nil }
        return end.timeIntervalSince(start)
    }
    
    /// Whether the task is currently within its window
    var isInWindow: Bool {
        guard let start = windowStart, let end = windowEnd else { return false }
        let now = Date()
        return now >= start && now <= end
    }
    
    /// Whether the window has passed
    var isOverdue: Bool {
        guard let end = windowEnd else { return false }
        return Date() > end && status != .done
    }
    
    /// Time until window starts
    var timeUntilWindow: TimeInterval? {
        guard let start = windowStart else { return nil }
        let interval = start.timeIntervalSinceNow
        return interval > 0 ? interval : nil
    }
    
    /// Friendly window description
    var windowDescription: String? {
        guard let start = windowStart else { return nil }
        
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(start) {
            formatter.dateFormat = "h:mm a"
            let startStr = formatter.string(from: start)
            if let end = windowEnd {
                let endStr = formatter.string(from: end)
                return "Today, \(startStr) - \(endStr)"
            }
            return "Today, \(startStr)"
        } else if calendar.isDateInTomorrow(start) {
            formatter.dateFormat = "h:mm a"
            let startStr = formatter.string(from: start)
            return "Tomorrow, \(startStr)"
        } else {
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return formatter.string(from: start)
        }
    }
}

// MARK: - Sync Helpers

extension RhythmTask {
    func markDirty() {
        self.dirtyFlag = true
    }
    
    func markSynced(serverId: String) {
        self.serverId = serverId
        self.dirtyFlag = false
        self.lastSyncedAt = Date()
    }
}

