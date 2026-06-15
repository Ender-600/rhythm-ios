//
//  EventLog.swift
//  Rhythm
//
//  All user actions logged for future learning
//  Local-first, batch uploaded later
//

import Foundation
import SwiftData

@Model
final class EventLog {
    // MARK: - Core Fields
    
    var id: UUID
    var eventType: String // EventType raw value
    var occurredAt: Date
    
    // MARK: - Context
    
    var taskId: UUID? // Related task, if any
    var metadata: String? // JSON-encoded additional data
    
    // MARK: - Device Context
    
    var deviceTime: Date // Local device time
    var timezone: String // User's timezone
    
    // MARK: - Sync Fields
    
    var serverId: String?
    var dirtyFlag: Bool
    var lastSyncedAt: Date?
    var uploadedAt: Date?
    
    // MARK: - Initialization
    
    init(
        eventType: EventType,
        taskId: UUID? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.id = UUID()
        self.eventType = eventType.rawValue
        self.occurredAt = Date()
        self.taskId = taskId
        self.deviceTime = Date()
        self.timezone = TimeZone.current.identifier
        self.serverId = nil
        self.dirtyFlag = true
        self.lastSyncedAt = nil
        self.uploadedAt = nil
        
        // Encode metadata as JSON
        if let metadata = metadata {
            if let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                self.metadata = jsonString
            }
        }
    }
    
    // MARK: - Metadata Helpers
    
    func decodedMetadata() -> [String: Any]? {
        guard let metadataString = metadata,
              let data = metadataString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    func addMetadata(key: String, value: Any) {
        var current = decodedMetadata() ?? [:]
        current[key] = value
        if let jsonData = try? JSONSerialization.data(withJSONObject: current),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.metadata = jsonString
        }
    }
}

// MARK: - Convenience Extensions

extension EventLog {
    /// Mark as uploaded
    func markUploaded(serverId: String? = nil) {
        if let serverId = serverId {
            self.serverId = serverId
        }
        self.dirtyFlag = false
        self.uploadedAt = Date()
        self.lastSyncedAt = Date()
    }
    
    /// Event type enum value
    var eventTypeEnum: EventType? {
        EventType(rawValue: eventType)
    }
}

// MARK: - Factory Methods

extension EventLog {
    /// Create a task-related event
    static func taskEvent(
        _ type: EventType,
        taskId: UUID,
        additionalMetadata: [String: Any]? = nil
    ) -> EventLog {
        EventLog(eventType: type, taskId: taskId, metadata: additionalMetadata)
    }
    
    /// Create a voice input event
    static func voiceEvent(
        _ type: EventType,
        duration: Double? = nil,
        transcriptLength: Int? = nil
    ) -> EventLog {
        var metadata: [String: Any] = [:]
        if let duration = duration {
            metadata["duration_seconds"] = duration
        }
        if let length = transcriptLength {
            metadata["transcript_length"] = length
        }
        return EventLog(eventType: type, metadata: metadata.isEmpty ? nil : metadata)
    }
    
    /// Create a notification event
    static func notificationEvent(
        _ type: EventType,
        notificationId: String,
        taskId: UUID? = nil
    ) -> EventLog {
        var metadata: [String: Any] = ["notification_id": notificationId]
        return EventLog(eventType: type, taskId: taskId, metadata: metadata)
    }
}

