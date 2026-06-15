//
//  EventLogService.swift
//  Rhythm
//
//  Local-first event logging for all user actions
//  Enables future learning and retrospective features
//

import Foundation
import SwiftData

@Observable
@MainActor
final class EventLogService {
    // MARK: - Published State
    
    private(set) var pendingUploadCount = 0
    
    // MARK: - Private Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await refreshPendingCount()
        }
    }
    
    // MARK: - Logging Methods
    
    /// Log a generic event
    func log(_ eventType: EventType, taskId: UUID? = nil, metadata: [String: Any]? = nil) {
        guard let context = modelContext else {
            print("EventLogService: ModelContext not configured")
            return
        }
        
        let event = EventLog(eventType: eventType, taskId: taskId, metadata: metadata)
        context.insert(event)
        
        do {
            try context.save()
            pendingUploadCount += 1
        } catch {
            print("Failed to save event log: \(error)")
        }
    }
    
    /// Log task creation
    func logTaskCreated(_ task: RhythmTask) {
        log(.taskCreated, taskId: task.id, metadata: [
            "title": task.title,
            "priority": task.priorityRaw,
            "has_window": task.windowStart != nil
        ])
    }
    
    /// Log task started
    func logTaskStarted(_ task: RhythmTask) {
        log(.taskStarted, taskId: task.id, metadata: [
            "snooze_count": task.snoozeCount,
            "is_in_window": task.isInWindow
        ])
    }
    
    /// Log task paused
    func logTaskPaused(_ task: RhythmTask) {
        log(.taskPaused, taskId: task.id, metadata: [
            "active_seconds": task.totalActiveSeconds
        ])
    }

    /// Log task resumed
    func logTaskResumed(_ task: RhythmTask) {
        log(.taskResumed, taskId: task.id, metadata: [
            "active_seconds": task.totalActiveSeconds
        ])
    }

    /// Log task completed
    func logTaskCompleted(_ task: RhythmTask) {
        log(.taskCompleted, taskId: task.id, metadata: [
            "actual_minutes": task.actualMinutes ?? 0,
            "estimated_minutes": task.estimatedMinutes ?? 0,
            "snooze_count": task.snoozeCount,
            "total_active_seconds": task.totalActiveSeconds
        ])
    }
    
    /// Log task skipped
    func logTaskSkipped(_ task: RhythmTask) {
        log(.taskSkipped, taskId: task.id, metadata: [
            "snooze_count": task.snoozeCount,
            "was_in_window": task.isInWindow
        ])
    }
    
    /// Log task snoozed
    func logTaskSnoozed(_ task: RhythmTask, option: SnoozeOption, newTime: Date?) {
        var metadata: [String: Any] = [
            "snooze_option": option.id,
            "snooze_count": task.snoozeCount
        ]
        if let time = newTime {
            metadata["new_start_time"] = ISO8601DateFormatter().string(from: time)
        }
        log(.taskSnoozed, taskId: task.id, metadata: metadata)
    }

    /// Log task rescheduled
    func logTaskRescheduled(_ task: RhythmTask) {
        var metadata: [String: Any] = [:]
        if let start = task.windowStart {
            metadata["new_start_time"] = ISO8601DateFormatter().string(from: start)
        }
        if let end = task.windowEnd {
            metadata["new_end_time"] = ISO8601DateFormatter().string(from: end)
        }
        log(.taskRescheduled, taskId: task.id, metadata: metadata)
    }

    /// Log voice input started
    func logVoiceInputStarted() {
        log(.voiceInputStarted)
    }
    
    /// Log voice input completed
    func logVoiceInputCompleted(duration: TimeInterval, transcriptLength: Int) {
        log(.voiceInputCompleted, metadata: [
            "duration_seconds": duration,
            "transcript_length": transcriptLength
        ])
    }
    
    /// Log voice input cancelled
    func logVoiceInputCancelled(duration: TimeInterval) {
        log(.voiceInputCancelled, metadata: [
            "duration_seconds": duration
        ])
    }
    
    /// Log notification interaction
    func logNotificationActioned(notificationId: String, taskId: UUID?, action: String) {
        log(.notificationActioned, taskId: taskId, metadata: [
            "notification_id": notificationId,
            "action": action
        ])
    }
    
    /// Log retrospective completed
    func logRetrospectiveCompleted(taskId: UUID, answers: [String: Any]) {
        log(.retrospectiveCompleted, taskId: taskId, metadata: answers)
    }
    
    /// Log app opened (including from Quick Add intent)
    func logAppOpened(source: String = "direct") {
        log(.appOpened, metadata: ["source": source])
    }
    
    // MARK: - Query Methods
    
    /// Get recent events for a task
    func recentEvents(for taskId: UUID, limit: Int = 10) -> [EventLog] {
        guard let context = modelContext else { return [] }
        
        let predicate = #Predicate<EventLog> { event in
            event.taskId == taskId
        }
        
        var descriptor = FetchDescriptor<EventLog>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.occurredAt, order: .reverse)]
        descriptor.fetchLimit = limit
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch events: \(error)")
            return []
        }
    }
    
    /// Get all unsynced events
    func unsyncedEvents(limit: Int = 100) -> [EventLog] {
        guard let context = modelContext else { return [] }
        
        let predicate = #Predicate<EventLog> { event in
            event.dirtyFlag == true
        }
        
        var descriptor = FetchDescriptor<EventLog>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.occurredAt)]
        descriptor.fetchLimit = limit
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch unsynced events: \(error)")
            return []
        }
    }
    
    /// Refresh pending upload count
    func refreshPendingCount() async {
        guard let context = modelContext else {
            pendingUploadCount = 0
            return
        }
        
        let predicate = #Predicate<EventLog> { event in
            event.dirtyFlag == true
        }
        
        var descriptor = FetchDescriptor<EventLog>(predicate: predicate)
        descriptor.propertiesToFetch = []
        
        do {
            pendingUploadCount = try context.fetchCount(descriptor)
        } catch {
            print("Failed to count pending events: \(error)")
            pendingUploadCount = 0
        }
    }
    
    /// Mark events as uploaded
    func markAsUploaded(_ events: [EventLog]) {
        for event in events {
            event.markUploaded()
        }
        
        do {
            try modelContext?.save()
        } catch {
            print("Failed to mark events as uploaded: \(error)")
        }
        
        Task {
            await refreshPendingCount()
        }
    }
    
    // MARK: - Analytics Helpers
    
    /// Get snooze pattern for a task
    func snoozePatternForTask(_ taskId: UUID) -> [(option: String, count: Int)] {
        let events = recentEvents(for: taskId, limit: 50)
        let snoozeEvents = events.filter { $0.eventTypeEnum == .taskSnoozed }
        
        var patterns: [String: Int] = [:]
        for event in snoozeEvents {
            if let metadata = event.decodedMetadata(),
               let option = metadata["snooze_option"] as? String {
                patterns[option, default: 0] += 1
            }
        }
        
        return patterns.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    /// Calculate average active time for completed tasks
    func averageActiveTimeForCompletedTasks() -> TimeInterval? {
        guard let context = modelContext else { return nil }
        
        let predicate = #Predicate<EventLog> { event in
            event.eventType == "task_completed"
        }
        
        var descriptor = FetchDescriptor<EventLog>(predicate: predicate)
        descriptor.fetchLimit = 50
        
        do {
            let events = try context.fetch(descriptor)
            let activeTimes = events.compactMap { event -> Double? in
                guard let metadata = event.decodedMetadata(),
                      let seconds = metadata["total_active_seconds"] as? Double else {
                    return nil
                }
                return seconds
            }
            
            guard !activeTimes.isEmpty else { return nil }
            return activeTimes.reduce(0, +) / Double(activeTimes.count)
        } catch {
            return nil
        }
    }
}

