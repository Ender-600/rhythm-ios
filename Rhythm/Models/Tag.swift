//
//  Tag.swift
//  Rhythm
//
//  Unified tag entity (unifies PRD's entity/tag concepts)
//

import Foundation
import SwiftData

@Model
final class Tag {
    // MARK: - Core Fields
    
    var id: UUID
    var name: String
    var normalizedName: String // Lowercase, trimmed for matching
    var colorHex: String? // Optional custom color
    var createdAt: Date
    
    // MARK: - Sync Fields
    
    var serverId: String?
    var dirtyFlag: Bool
    var lastSyncedAt: Date?
    
    // MARK: - Relationships
    
    @Relationship(inverse: \RhythmTask.tags)
    var tasks: [RhythmTask]?
    
    // MARK: - Initialization
    
    init(
        name: String,
        colorHex: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.normalizedName = Tag.normalize(name)
        self.colorHex = colorHex
        self.createdAt = Date()
        self.serverId = nil
        self.dirtyFlag = true
        self.lastSyncedAt = nil
        self.tasks = []
    }
    
    // MARK: - Tag Normalization
    
    /// Normalize tag name: lowercase, trimmed, max 20 chars
    static func normalize(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let maxLength = min(lowercased.count, 20)
        return String(lowercased.prefix(maxLength))
    }
    
    /// Check if two tag names are equivalent after normalization
    static func areEquivalent(_ name1: String, _ name2: String) -> Bool {
        normalize(name1) == normalize(name2)
    }
}

// MARK: - Convenience Extensions

extension Tag {
    /// Display name with # prefix
    var displayName: String {
        "#\(name)"
    }
    
    /// Mark as synced with server
    func markSynced(serverId: String) {
        self.serverId = serverId
        self.dirtyFlag = false
        self.lastSyncedAt = Date()
    }
    
    /// Mark as needing sync
    func markDirty() {
        self.dirtyFlag = true
    }
}

