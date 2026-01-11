//
//  PlanViewModel.swift
//  Rhythm
//
//  ViewModel for the Plan view (day/week/month)
//  Shows a "plan sketch" - flexible, not rigid
//

import Foundation
import SwiftData

@Observable
@MainActor
final class PlanViewModel {
    // MARK: - Published State
    
    var selectedPeriod: PlanPeriod = .day
    private(set) var tasks: [RhythmTask] = []
    private(set) var isLoading = false
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private let notificationScheduler: NotificationScheduler
    private let eventLogService: EventLogService
    
    // MARK: - Types
    
    enum PlanPeriod: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        
        var dateRange: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .day:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 1, to: start)!
                return (start, end)
            case .week:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .day, value: 7, to: start)!
                return (start, end)
            case .month:
                let start = calendar.startOfDay(for: now)
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                return (start, end)
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
            await loadTasks()
        }
    }
    
    // MARK: - Data Loading
    
    func loadTasks() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        let range = selectedPeriod.dateRange
        let startDate = range.start
        let endDate = range.end
        
        // Fetch tasks that are not done and have a window start time
        let predicate = #Predicate<RhythmTask> { task in
            task.statusRaw != "done" &&
            task.windowStart != nil
        }
        
        var descriptor = FetchDescriptor<RhythmTask>(predicate: predicate)
        descriptor.sortBy = [
            SortDescriptor(\.windowStart),
            SortDescriptor(\.priorityRaw)
        ]
        
        do {
            let allTasks = try context.fetch(descriptor)
            // Filter by date range in memory (forced unwrap is not supported in predicates)
            tasks = allTasks.filter { task in
                guard let windowStart = task.windowStart else { return false }
                return windowStart >= startDate && windowStart < endDate
            }
        } catch {
            print("Failed to fetch tasks: \(error)")
            tasks = []
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadTasks()
    }
    
    // MARK: - Computed Properties
    
    /// Tasks grouped by priority
    var tasksByPriority: [TaskPriority: [RhythmTask]] {
        Dictionary(grouping: tasks) { $0.priority }
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
    
    /// Time blocks for visual display
    var timeBlocks: [TimeBlock] {
        tasks.compactMap { task -> TimeBlock? in
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
        return tasks.first { task in
            guard let start = task.windowStart else { return false }
            return start > now && task.status == .notStarted
        }
    }
    
    /// Currently active task (in window and in progress)
    var activeTask: RhythmTask? {
        tasks.first { $0.isInWindow && $0.status == .inProgress }
    }
    
    /// Summary text for the period
    var summaryText: String {
        let total = tasks.count
        let urgent = urgentTasks.count
        
        if total == 0 {
            return "Your \(selectedPeriod.rawValue.lowercased()) is wide open"
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
        await loadTasks()
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
        await loadTasks()
    }
    
    // MARK: - Period Selection
    
    func selectPeriod(_ period: PlanPeriod) async {
        selectedPeriod = period
        await loadTasks()
    }
}

// MARK: - Time Helpers

extension PlanViewModel {
    /// Get tasks for a specific hour
    func tasks(forHour hour: Int, on date: Date = Date()) -> [RhythmTask] {
        let calendar = Calendar.current
        
        return tasks.filter { task in
            guard let start = task.windowStart else { return false }
            let taskHour = calendar.component(.hour, from: start)
            let taskDay = calendar.startOfDay(for: start)
            let targetDay = calendar.startOfDay(for: date)
            return taskHour == hour && taskDay == targetDay
        }
    }
    
    /// Get the busy hours for today
    var busyHours: Set<Int> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var hours = Set<Int>()
        
        for task in tasks {
            guard let start = task.windowStart,
                  calendar.startOfDay(for: start) == today else { continue }
            
            let startHour = calendar.component(.hour, from: start)
            hours.insert(startHour)
            
            if let end = task.windowEnd {
                let endHour = calendar.component(.hour, from: end)
                for h in startHour...endHour {
                    hours.insert(h)
                }
            }
        }
        
        return hours
    }
}

