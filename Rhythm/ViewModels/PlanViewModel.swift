//
//  PlanViewModel.swift
//  Rhythm
//
//  ViewModel for the Plan view (Today/3-Day/Month views)
//  Shows a "plan sketch" - flexible, not rigid
//

import Foundation
import SwiftData

@Observable
@MainActor
final class PlanViewModel {
    // MARK: - Published State
    
    var selectedPeriod: PlanPeriod = .today
    private(set) var allTasks: [RhythmTask] = []
    private(set) var isLoading = false
    
    // State for three-day view (center date for horizontal scrolling)
    var threeDayCenterDate: Date = Date()
    
    // State for month view (current visible month)
    var selectedMonth: Date = Date()
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private let notificationScheduler: NotificationScheduler
    private let eventLogService: EventLogService
    
    // MARK: - Types
    
    enum PlanPeriod: String, CaseIterable {
        case today = "Today"
        case nearFuture = "3 Days"
        case monthOverview = "Month"
        
        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .nearFuture: return "calendar.day.timeline.left"
            case .monthOverview: return "calendar"
            }
        }
    }
    
    struct TimeBlock: Identifiable {
        let id: String
        let task: RhythmTask
        let startTime: Date
        let endTime: Date
        let isActive: Bool
        let hasBuffer: Bool
        
        var duration: TimeInterval {
            endTime.timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Initialization
    
    init(
        notificationScheduler: NotificationScheduler,
        eventLogService: EventLogService
    ) {
        self.notificationScheduler = notificationScheduler
        self.eventLogService = eventLogService
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadAllTasks()
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all tasks (not filtered by date) for flexible view filtering
    func loadAllTasks() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        // Fetch all tasks that are not done
        let predicate = #Predicate<RhythmTask> { task in
            task.statusRaw != "done"
        }
        
        var descriptor = FetchDescriptor<RhythmTask>(predicate: predicate)
        descriptor.sortBy = [
            SortDescriptor(\.windowStart),
            SortDescriptor(\.priorityRaw)
        ]
        
        do {
            allTasks = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch tasks: \(error)")
            allTasks = []
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadAllTasks()
    }
    
    // MARK: - Date-Based Task Filtering
    
    /// Get tasks for a specific date
    func tasksForDate(_ date: Date) -> [RhythmTask] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        return allTasks.filter { task in
            guard let windowStart = task.windowStart else { return false }
            return windowStart >= dayStart && windowStart < dayEnd
        }.sorted { task1, task2 in
            guard let start1 = task1.windowStart, let start2 = task2.windowStart else { return false }
            return start1 < start2
        }
    }
    
    /// Get tasks grouped by date for a month
    func tasksForMonth(_ month: Date) -> [Date: [RhythmTask]] {
        let calendar = Calendar.current
        
        // Get the first and last day of the month
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return [:]
        }
        
        var result: [Date: [RhythmTask]] = [:]
        
        // Filter tasks within this month
        let monthTasks = allTasks.filter { task in
            guard let windowStart = task.windowStart else { return false }
            return windowStart >= monthInterval.start && windowStart < monthInterval.end
        }
        
        // Group by day
        for task in monthTasks {
            guard let windowStart = task.windowStart else { continue }
            let dayStart = calendar.startOfDay(for: windowStart)
            
            if result[dayStart] == nil {
                result[dayStart] = []
            }
            result[dayStart]?.append(task)
        }
        
        // Sort tasks within each day
        for (date, tasks) in result {
            result[date] = tasks.sorted { task1, task2 in
                guard let start1 = task1.windowStart, let start2 = task2.windowStart else { return false }
                return start1 < start2
            }
        }
        
        return result
    }
    
    // MARK: - Convenience Properties
    
    /// Tasks for today (used by TodayTimelineView)
    var todayTasks: [RhythmTask] {
        tasksForDate(Date())
    }
    
    // MARK: - Computed Properties
    
    /// Tasks grouped by priority (for today)
    var tasksByPriority: [TaskPriority: [RhythmTask]] {
        Dictionary(grouping: todayTasks) { $0.priority }
    }
    
    /// Urgent priority tasks
    var urgentTasks: [RhythmTask] {
        tasksByPriority[.urgent] ?? []
    }
    
    /// Normal priority tasks
    var normalTasks: [RhythmTask] {
        tasksByPriority[.normal] ?? []
    }
    
    /// Low priority tasks
    var lowTasks: [RhythmTask] {
        tasksByPriority[.low] ?? []
    }
    
    /// Time blocks for visual display (for today)
    var timeBlocks: [TimeBlock] {
        todayTasks.compactMap { task -> TimeBlock? in
            guard let start = task.windowStart,
                  let end = task.windowEnd else { return nil }
            
            return TimeBlock(
                id: task.id.uuidString,
                task: task,
                startTime: start,
                endTime: end,
                isActive: task.status == .inProgress,
                hasBuffer: task.bufferMinutes > 0
            )
        }
    }
    
    /// Next upcoming task
    var nextTask: RhythmTask? {
        let now = Date()
        return todayTasks.first { task in
            guard let start = task.windowStart else { return false }
            return start > now && task.status == .notStarted
        }
    }
    
    /// Currently active task (in window and in progress)
    var activeTask: RhythmTask? {
        todayTasks.first { $0.isInWindow && $0.status == .inProgress }
    }
    
    /// Summary text for the period
    var summaryText: String {
        let tasks = todayTasks
        let total = tasks.count
        let urgent = urgentTasks.count
        
        if total == 0 {
            return "Your day is wide open"
        }
        
        var parts: [String] = []
        if urgent > 0 {
            parts.append("\(urgent) urgent\(urgent == 1 ? "" : " tasks")")
        }
        if total - urgent > 0 {
            parts.append("\(total - urgent) other\(total - urgent == 1 ? "" : "s")")
        }
        
        return parts.joined(separator: ", ")
    }
    
    // MARK: - Task Actions
    
    func snoozeTask(_ task: RhythmTask, option: SnoozeOption) async {
        guard let newTime = option.calculateNewTime() else {
            return
        }
        
        task.snooze(to: newTime, option: option)
        eventLogService.logTaskSnoozed(task, option: option, newTime: newTime)
        
        // Reschedule notifications
        await notificationScheduler.rescheduleNotifications(for: task)
        
        try? modelContext?.save()
        await loadAllTasks()
    }
    
    func startTask(_ task: RhythmTask) {
        task.start()
        eventLogService.logTaskStarted(task)
        try? modelContext?.save()
    }
    
    func skipTask(_ task: RhythmTask) async {
        task.skip()
        eventLogService.logTaskSkipped(task)
        
        notificationScheduler.cancelNotifications(for: task.id)
        
        try? modelContext?.save()
        await loadAllTasks()
    }
    
    // MARK: - Period Selection
    
    func selectPeriod(_ period: PlanPeriod) {
        selectedPeriod = period
    }
    
    // MARK: - Navigation Helpers
    
    /// Move three-day view to show today/tomorrow/day-after-tomorrow
    func resetToToday() {
        threeDayCenterDate = Date()
    }
    
    /// Move month view to current month
    func resetToCurrentMonth() {
        selectedMonth = Date()
    }
}

// MARK: - Time Helpers

extension PlanViewModel {
    /// Get tasks for a specific hour on a specific date
    func tasks(forHour hour: Int, on date: Date = Date()) -> [RhythmTask] {
        let calendar = Calendar.current
        let tasksForDay = tasksForDate(date)
        
        return tasksForDay.filter { task in
            guard let start = task.windowStart else { return false }
            let taskHour = calendar.component(.hour, from: start)
            return taskHour == hour
        }
    }
    
    /// Get the busy hours for a specific date
    func busyHours(for date: Date) -> Set<Int> {
        let calendar = Calendar.current
        let tasksForDay = tasksForDate(date)
        
        var hours = Set<Int>()
        
        for task in tasksForDay {
            guard let start = task.windowStart else { continue }
            
            let startHour = calendar.component(.hour, from: start)
            hours.insert(startHour)
            
            if let end = task.windowEnd {
                let endHour = calendar.component(.hour, from: end)
                for h in startHour...min(endHour, 23) {
                    hours.insert(h)
                }
            }
        }
        
        return hours
    }
    
    /// Get the busy hours for today (convenience)
    var busyHours: Set<Int> {
        busyHours(for: Date())
    }
    
    /// Generate date range for three-day view (extended for scrolling)
    func dateRangeForThreeDayView(daysBeforeToday: Int = 30, daysAfterToday: Int = 60) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var dates: [Date] = []
        
        // Days before today
        for i in (1...daysBeforeToday).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        
        // Today
        dates.append(today)
        
        // Days after today
        for i in 1...daysAfterToday {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    /// Generate months for month view (for infinite scrolling)
    func monthsForMonthView(monthsBefore: Int = 12, monthsAfter: Int = 12) -> [Date] {
        let calendar = Calendar.current
        let currentMonth = calendar.startOfMonth(for: Date())
        
        var months: [Date] = []
        
        // Months before
        for i in (1...monthsBefore).reversed() {
            if let month = calendar.date(byAdding: .month, value: -i, to: currentMonth) {
                months.append(month)
            }
        }
        
        // Current month
        months.append(currentMonth)
        
        // Months after
        for i in 1...monthsAfter {
            if let month = calendar.date(byAdding: .month, value: i, to: currentMonth) {
                months.append(month)
            }
        }
        
        return months
    }
}

