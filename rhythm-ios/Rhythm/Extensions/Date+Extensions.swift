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
    
    /// Add days
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    // MARK: - Calendar Components
    
    /// Day of the month (1-31)
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    /// Month number (1-12)
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
    
    /// Year
    var year: Int {
        Calendar.current.component(.year, from: self)
    }
    
    /// Hour of day (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    /// Minute (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
    
    /// Short weekday name (e.g., "Mon", "Tue")
    var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }
    
    /// Full weekday name (e.g., "Monday", "Tuesday")
    var weekdayFull: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Month and year string (e.g., "January 2024")
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Short month and day (e.g., "Jan 15")
    var shortMonthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    /// Day with ordinal suffix (e.g., "15th")
    var dayWithSuffix: String {
        let day = self.day
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }
    
    // MARK: - Month Helpers
    
    /// Get all days in this date's month
    func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: self),
              let monthFirstDay = calendar.dateComponents([.year, .month], from: self).date else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            days.append(currentDate)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDay
        }
        
        return days
    }
    
    /// Get the number of days in this date's month
    var numberOfDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }
    
    /// Weekday index (1 = Sunday, 7 = Saturday)
    var weekdayIndex: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if this date is in the same month as another date
    func isSameMonth(as other: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.month, from: self) == calendar.component(.month, from: other) &&
               calendar.component(.year, from: self) == calendar.component(.year, from: other)
    }
    
    /// Check if this date is in the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
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

// MARK: - Calendar Extensions

extension Calendar {
    /// Get the start of the month for a given date
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    /// Get the end of the month for a given date
    func endOfMonth(for date: Date) -> Date {
        guard let startOfNextMonth = self.date(byAdding: .month, value: 1, to: startOfMonth(for: date)) else {
            return date
        }
        return self.date(byAdding: .second, value: -1, to: startOfNextMonth) ?? date
    }
    
    /// Get all dates in a month
    func datesInMonth(for date: Date) -> [Date] {
        guard let range = self.range(of: .day, in: .month, for: date) else { return [] }
        
        let monthStart = startOfMonth(for: date)
        return range.compactMap { day -> Date? in
            self.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }
}
