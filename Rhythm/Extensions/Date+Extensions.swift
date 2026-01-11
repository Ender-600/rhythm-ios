//
//  Date+Extensions.swift
//  Rhythm
//
//  Date helpers for time window handling
//

import Foundation

extension Date {
    // MARK: - Relative Descriptions
    
    /// Friendly relative time description
    var relativeDescription: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: self))"
        }
        
        if calendar.isDateInTomorrow(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Tomorrow at \(formatter.string(from: self))"
        }
        
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        
        // Within this week
        let daysAway = calendar.dateComponents([.day], from: now, to: self).day ?? 0
        if daysAway > 0 && daysAway < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE 'at' h:mm a"
            return formatter.string(from: self)
        }
        
        // Further out
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter.string(from: self)
    }
    
    /// Short time only (e.g., "3:30 PM")
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    
    /// Time range string (e.g., "3:30 - 5:00 PM")
    func timeRange(to end: Date) -> String {
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        
        let calendar = Calendar.current
        let sameAmPm = (calendar.component(.hour, from: self) < 12) ==
                       (calendar.component(.hour, from: end) < 12)
        
        if sameAmPm {
            startFormatter.dateFormat = "h:mm"
            endFormatter.dateFormat = "h:mm a"
        } else {
            startFormatter.dateFormat = "h:mm a"
            endFormatter.dateFormat = "h:mm a"
        }
        
        return "\(startFormatter.string(from: self)) - \(endFormatter.string(from: end))"
    }
    
    // MARK: - Date Calculations
    
    /// Start of the current day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of the current day (23:59:59)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    /// Start of the current hour
    var startOfHour: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        return calendar.date(from: components)!
    }
    
    /// Add hours
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
    
    /// Add minutes
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
    
    // MARK: - Time Window Helpers
    
    /// Check if this date is within a time window
    func isWithin(start: Date, end: Date) -> Bool {
        self >= start && self <= end
    }
    
    /// Create a time window from now with given duration
    static func windowFromNow(durationMinutes: Int) -> (start: Date, end: Date) {
        let start = Date()
        let end = start.adding(minutes: durationMinutes)
        return (start, end)
    }
    
    /// Create "tonight" window (7-10 PM today or tomorrow)
    static func tonightWindow() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = AppConfig.tonightStartHour
        components.minute = 0
        
        guard var start = calendar.date(from: components) else { return nil }
        
        // If past tonight start, use tomorrow
        if start < now {
            start = calendar.date(byAdding: .day, value: 1, to: start)!
        }
        
        components = calendar.dateComponents([.year, .month, .day], from: start)
        components.hour = AppConfig.tonightEndHour
        
        guard let end = calendar.date(from: components) else { return nil }
        
        return (start, end)
    }
    
    /// Create "tomorrow morning" window (9 AM - 12 PM tomorrow)
    static func tomorrowMorningWindow() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        startComponents.hour = AppConfig.defaultMorningHour
        startComponents.minute = 0
        
        var endComponents = startComponents
        endComponents.hour = 12
        
        guard let start = calendar.date(from: startComponents),
              let end = calendar.date(from: endComponents) else { return nil }
        
        return (start, end)
    }
}

// MARK: - Time Interval Extensions

extension TimeInterval {
    /// Format as duration string (e.g., "1h 30m")
    var durationString: String {
        let totalMinutes = Int(self / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Format as short duration (e.g., "1:30")
    var shortDurationString: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

