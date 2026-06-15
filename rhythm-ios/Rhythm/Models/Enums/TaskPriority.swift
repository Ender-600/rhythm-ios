//
//  TaskPriority.swift
//  Rhythm
//
//  Urgent/Normal/Low priority levels
//

import Foundation
import SwiftUI

enum TaskPriority: String, Codable, CaseIterable {
    case urgent = "urgent"
    case normal = "normal"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .urgent: return "Urgent"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
    
    /// Gentle, non-pushy descriptions
    var gentleDescription: String {
        switch self {
        case .urgent: return "This needs your attention soon"
        case .normal: return "Regular priority"
        case .low: return "Do this when you have time"
        }
    }
    
    var color: Color {
        switch self {
        case .urgent: return .rhythmCoral
        case .normal: return .rhythmAmber
        case .low: return .rhythmSage
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .urgent: return 0
        case .normal: return 1
        case .low: return 2
        }
    }
}

