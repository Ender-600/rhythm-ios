//
//  SnoozeOption.swift
//  Rhythm
//
//  Snooze presets - always available, never shameful
//

import Foundation

enum SnoozeOption: Codable, Identifiable, Equatable, Hashable {
    case tenMinutes
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case tonight
    case tomorrow
    case custom(Int) // Custom minutes
    
    var id: String {
        switch self {
        case .tenMinutes: return "10_min"
        case .fifteenMinutes: return "15_min"
        case .thirtyMinutes: return "30_min"
        case .oneHour: return "1_hour"
        case .twoHours: return "2_hours"
        case .tonight: return "tonight"
        case .tomorrow: return "tomorrow"
        case .custom(let mins): return "custom_\(mins)"
        }
    }
    
    var displayName: String {
        switch self {
        case .tenMinutes: return "10 minutes"
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .tonight: return "Tonight"
        case .tomorrow: return "Tomorrow"
        case .custom(let mins): return "\(mins) minutes"
        }
    }
    
    /// Gentle, supportive copy
    var gentleLabel: String {
        switch self {
        case .tenMinutes: return "Just a quick break"
        case .fifteenMinutes: return "A short pause"
        case .thirtyMinutes: return "A little more time"
        case .oneHour: return "Come back in an hour"
        case .twoHours: return "Take your time"
        case .tonight: return "Later this evening"
        case .tomorrow: return "Fresh start tomorrow"
        case .custom: return "When works for you?"
        }
    }
    
    /// Standard options for picker
    static var standardOptions: [SnoozeOption] {
        [.fifteenMinutes, .thirtyMinutes, .oneHour, .twoHours, .tonight, .tomorrow]
    }
    
    /// Calculate the new time based on snooze option
    func calculateNewTime(from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        
        switch self {
        case .tenMinutes:
            return calendar.date(byAdding: .minute, value: 10, to: date)
        case .fifteenMinutes:
            return calendar.date(byAdding: .minute, value: 15, to: date)
        case .thirtyMinutes:
            return calendar.date(byAdding: .minute, value: 30, to: date)
        case .oneHour:
            return calendar.date(byAdding: .hour, value: 1, to: date)
        case .twoHours:
            return calendar.date(byAdding: .hour, value: 2, to: date)
        case .tonight:
            // Tonight = 7 PM today (or tomorrow if past 7 PM)
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = 19
            components.minute = 0
            if let tonightTime = calendar.date(from: components), tonightTime > date {
                return tonightTime
            }
            // If past 7 PM, return nil (use tomorrow instead)
            return nil
        case .tomorrow:
            // Tomorrow morning = 9 AM tomorrow
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components)
        case .custom(let minutes):
            return calendar.date(byAdding: .minute, value: minutes, to: date)
        }
    }
}

