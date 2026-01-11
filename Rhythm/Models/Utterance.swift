//
//  Utterance.swift
//  Rhythm
//
//  Raw speech capture record - preserves user's exact words
//

import Foundation
import SwiftData

@Model
final class Utterance {
    // MARK: - Core Fields
    
    var id: UUID
    var rawText: String // Full transcription
    var recordedAt: Date
    var durationSeconds: Double? // Recording duration
    var locale: String // Language/locale of speech
    
    // MARK: - Processing State
    
    var isParsed: Bool
    var parsedAt: Date?
    var parseError: String? // If parsing failed
    
    // MARK: - Audio Reference (future: store audio for replay)
    
    var audioFileURL: String? // Local file path if stored
    
    // MARK: - Sync Fields
    
    var serverId: String?
    var dirtyFlag: Bool
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    @Relationship(inverse: \RhythmTask.utterance)
    var task: RhythmTask?
    
    // MARK: - Initialization
    
    init(
        rawText: String,
        durationSeconds: Double? = nil,
        locale: String = Locale.current.identifier
    ) {
        self.id = UUID()
        self.rawText = rawText
        self.recordedAt = Date()
        self.durationSeconds = durationSeconds
        self.locale = locale
        self.isParsed = false
        self.parsedAt = nil
        self.parseError = nil
        self.audioFileURL = nil
        self.serverId = nil
        self.dirtyFlag = true
        self.lastSyncedAt = nil
    }
    
    // MARK: - Processing
    
    func markParsed() {
        self.isParsed = true
        self.parsedAt = Date()
        self.parseError = nil
    }
    
    func markParseError(_ error: String) {
        self.isParsed = false
        self.parseError = error
    }
}

// MARK: - Convenience Extensions

extension Utterance {
    /// Preview of the utterance (first 50 chars)
    var preview: String {
        if rawText.count <= 50 {
            return rawText
        }
        return String(rawText.prefix(47)) + "..."
    }
    
    /// Mark as synced with server
    func markSynced(serverId: String) {
        self.serverId = serverId
        self.dirtyFlag = false
        self.lastSyncedAt = Date()
    }
}

