//
//  PlanViewModel.swift
//  Rhythm
//
//  ViewModel for the zoomable Plan calendar
//  Shows a "plan sketch" - flexible, not rigid
//

import Foundation
import SwiftData

@Observable
@MainActor
final class PlanViewModel {
    // MARK: - Published State
    
    var zoomLevel: ZoomLevel = .day
    var focusedDate: Date = Date()
    private(set) var allTasks: [RhythmTask] = []
    private(set) var isLoading = false
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private let notificationScheduler: NotificationScheduler
    private let eventLogService: EventLogService
    private let calendarService: CalendarService?
    
    // MARK: - Types
    
    enum ZoomLevel: Int, CaseIterable {
        case month
        case week
        case day

        var title: String {
            switch self {
            case .month: return "Month"
            case .week: return "Week"
            case .day: return "Day"
            }
        }
        
        var icon: String {
            switch self {
            case .month: return "calendar"
            case .week: return "calendar.day.timeline.left"
            case .day: return "clock"
            }
        }
    }

    enum PlanCreationError: LocalizedError {
        case missingModelContext
        case invalidTimeRange

        var errorDescription: String? {
            switch self {
            case .missingModelContext:
                return "The planner is not ready yet."
            case .invalidTimeRange:
                return "Choose an end time after the start time."
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
        eventLogService: EventLogService,
        calendarService: CalendarService? = nil
    ) {
        self.notificationScheduler = notificationScheduler
        self.eventLogService = eventLogService
        self.calendarService = calendarService
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
    
    /// Tasks for today (used by actions that are explicitly about today)
    var todayTasks: [RhythmTask] {
        tasksForDate(Date())
    }

    var focusedDayTasks: [RhythmTask] {
        tasksForDate(focusedDate)
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
        let tasks: [RhythmTask]

        switch zoomLevel {
        case .day:
            tasks = focusedDayTasks
        case .week:
            tasks = weekDates(containing: focusedDate).flatMap(tasksForDate)
        case .month:
            tasks = tasksForMonth(focusedDate).values.flatMap { $0 }
        }

        let total = tasks.count
        let urgent = tasks.filter { $0.priority == .urgent }.count
        
        if total == 0 {
            switch zoomLevel {
            case .day: return "This day is wide open"
            case .week: return "This week is wide open"
            case .month: return "This month is wide open"
            }
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

    @discardableResult
    func createPlan(
        title: String,
        start: Date,
        end: Date,
        priority: TaskPriority,
        openingAction: String?,
        notes: String?
    ) async throws -> RhythmTask {
        guard let context = modelContext else {
            throw PlanCreationError.missingModelContext
        }
        guard end > start else {
            throw PlanCreationError.invalidTimeRange
        }

        let task = RhythmTask(
            title: title,
            windowStart: start,
            windowEnd: end,
            priority: priority,
            openingAction: openingAction
        )
        task.estimatedMinutes = max(1, Int(end.timeIntervalSince(start) / 60))
        task.notes = notes

        context.insert(task)
        try context.save()

        eventLogService.logTaskCreated(task)
        await notificationScheduler.scheduleWindowStart(for: task)
        await notificationScheduler.scheduleWindowEnd(for: task)

        if UserDefaults.standard.bool(forKey: CalendarService.addRhythmPlansToAppleCalendarKey),
           let calendarService,
           calendarService.accessLevel.canWrite {
            do {
                try calendarService.upsertCalendarEvent(for: task)
                try context.save()
            } catch {
                print("Failed to add plan to Apple Calendar: \(error)")
            }
        }

        await loadAllTasks()

        return task
    }
    
    // MARK: - Calendar Navigation

    var canZoomIn: Bool { zoomLevel != .day }

    var canZoomOut: Bool { zoomLevel != .month }

    func zoomIn(focusing date: Date? = nil) {
        if let date {
            focusedDate = Calendar.current.startOfDay(for: date)
        }

        guard let next = ZoomLevel(rawValue: zoomLevel.rawValue + 1) else { return }
        zoomLevel = next
    }

    func zoomOut() {
        guard let next = ZoomLevel(rawValue: zoomLevel.rawValue - 1) else { return }
        zoomLevel = next
    }

    func focus(on date: Date, zoomTo level: ZoomLevel? = nil) {
        focusedDate = Calendar.current.startOfDay(for: date)
        if let level {
            zoomLevel = level
        }
    }

    func weekDates(containing date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return [calendar.startOfDay(for: date)]
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: interval.start)
        }
    }

    var focusedRangeTitle: String {
        switch zoomLevel {
        case .day:
            return focusedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        case .week:
            let dates = weekDates(containing: focusedDate)
            guard let first = dates.first, let last = dates.last else { return "" }
            return "\(first.formatted(.dateTime.month(.abbreviated).day())) - \(last.formatted(.dateTime.month(.abbreviated).day()))"
        case .month:
            return focusedDate.formatted(.dateTime.month(.wide).year())
        }
    }
    
    func resetToToday() {
        focusedDate = Date()
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
