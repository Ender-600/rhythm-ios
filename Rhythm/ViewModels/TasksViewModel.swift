//
//  TasksViewModel.swift
//  Rhythm
//
//  ViewModel for the Tasks view (Board + List)
//  All actions logged for learning
//

import Foundation
import SwiftData

@Observable
@MainActor
final class TasksViewModel {
    // MARK: - Published State
    
    var viewMode: ViewMode = .board
    var sortOption: SortOption = .window
    private(set) var tasks: [RhythmTask] = []
    private(set) var isLoading = false
    
    // Task interaction state
    var selectedTask: RhythmTask?
    var showingSnoozeSheet = false
    var showingCompletionSheet = false
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private let eventLogService: EventLogService
    private let notificationScheduler: NotificationScheduler
    
    // MARK: - Types
    
    enum ViewMode: String, CaseIterable {
        case board = "Board"
        case list = "List"
        
        var icon: String {
            switch self {
            case .board: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case window = "Time Window"
        case priority = "Priority"
        case created = "Created"
        case title = "Title"
    }
    
    // MARK: - Initialization
    
    init(
        eventLogService: EventLogService,
        notificationScheduler: NotificationScheduler
    ) {
        self.eventLogService = eventLogService
        self.notificationScheduler = notificationScheduler
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
        
        var descriptor = FetchDescriptor<RhythmTask>()
        
        // Apply sorting
        switch sortOption {
        case .window:
            descriptor.sortBy = [SortDescriptor(\.windowStart, order: .forward)]
        case .priority:
            descriptor.sortBy = [SortDescriptor(\.priorityRaw)]
        case .created:
            descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        case .title:
            descriptor.sortBy = [SortDescriptor(\.title)]
        }
        
        do {
            tasks = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch tasks: \(error)")
            tasks = []
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadTasks()
    }
    
    // MARK: - Computed Properties - Board Columns
    
    var notStartedTasks: [RhythmTask] {
        tasks.filter { $0.status == .notStarted }
    }
    
    var inProgressTasks: [RhythmTask] {
        tasks.filter { $0.status == .inProgress }
    }
    
    var doneTasks: [RhythmTask] {
        tasks.filter { $0.status == .done }
    }
    
    /// Summary counts
    var taskCounts: (notStarted: Int, inProgress: Int, done: Int) {
        (notStartedTasks.count, inProgressTasks.count, doneTasks.count)
    }
    
    // MARK: - Task Actions
    
    func startTask(_ task: RhythmTask) {
        // Pause any currently active task
        if let active = inProgressTasks.first, active.id != task.id {
            pauseTask(active)
        }
        
        task.start()
        eventLogService.logTaskStarted(task)
        
        try? modelContext?.save()
    }
    
    func pauseTask(_ task: RhythmTask) {
        task.pause()
        eventLogService.logTaskPaused(task)
        
        try? modelContext?.save()
    }
    
    func resumeTask(_ task: RhythmTask) {
        task.resume()
        eventLogService.logTaskStarted(task)
        
        try? modelContext?.save()
    }
    
    func completeTask(_ task: RhythmTask, actualMinutes: Int? = nil) {
        task.complete(actualMinutes: actualMinutes)
        eventLogService.logTaskCompleted(task)
        
        notificationScheduler.cancelNotifications(for: task.id)
        
        try? modelContext?.save()
    }
    
    func skipTask(_ task: RhythmTask) {
        task.skip()
        eventLogService.logTaskSkipped(task)
        
        notificationScheduler.cancelNotifications(for: task.id)
        
        try? modelContext?.save()
    }
    
    func snoozeTask(_ task: RhythmTask, option: SnoozeOption) async {
        guard let newTime = option.calculateNewTime() else {
            // Custom - show picker
            selectedTask = task
            showingSnoozeSheet = true
            return
        }
        
        task.snooze(to: newTime, option: option)
        eventLogService.logTaskSnoozed(task, option: option, newTime: newTime)
        
        await notificationScheduler.rescheduleNotifications(for: task)
        
        try? modelContext?.save()
    }
    
    func snoozeTaskToCustomTime(_ task: RhythmTask, start: Date, end: Date?) {
        task.snooze(to: start, newEnd: end, option: .custom)
        eventLogService.logTaskSnoozed(task, option: .custom, newTime: start)
        
        Task {
            await notificationScheduler.rescheduleNotifications(for: task)
        }
        
        try? modelContext?.save()
        showingSnoozeSheet = false
    }
    
    func deleteTask(_ task: RhythmTask) {
        eventLogService.log(.taskDeleted, taskId: task.id)
        notificationScheduler.cancelNotifications(for: task.id)
        
        modelContext?.delete(task)
        try? modelContext?.save()
        
        Task {
            await loadTasks()
        }
    }
    
    // MARK: - Bulk Actions
    
    func completeAllInProgress() {
        for task in inProgressTasks {
            completeTask(task)
        }
    }
    
    func clearDoneTasks(olderThan days: Int = 7) async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let oldDone = doneTasks.filter { task in
            guard let completed = task.completedAt else { return false }
            return completed < cutoff
        }
        
        for task in oldDone {
            modelContext?.delete(task)
        }
        
        try? modelContext?.save()
        await loadTasks()
    }
    
    // MARK: - Completion Flow
    
    func showCompletionFlow(for task: RhythmTask) {
        selectedTask = task
        showingCompletionSheet = true
    }
    
    func confirmCompletion(actualMinutes: Int?, notes: String?) {
        guard let task = selectedTask else { return }
        
        if let minutes = actualMinutes {
            task.actualMinutes = minutes
        }
        if let notes = notes, !notes.isEmpty {
            task.notes = notes
        }
        
        completeTask(task, actualMinutes: actualMinutes)
        
        showingCompletionSheet = false
        selectedTask = nil
    }
    
    // MARK: - View Mode & Sort
    
    func toggleViewMode() {
        viewMode = viewMode == .board ? .list : .board
    }
    
    func setSortOption(_ option: SortOption) async {
        sortOption = option
        await loadTasks()
    }
}

// MARK: - Task Filtering

extension TasksViewModel {
    /// Filter tasks by tags
    func tasks(withTag tagName: String) -> [RhythmTask] {
        let normalized = Tag.normalize(tagName)
        return tasks.filter { task in
            task.tags?.contains { $0.normalizedName == normalized } ?? false
        }
    }
    
    /// Filter tasks by priority
    func tasks(withPriority priority: TaskPriority) -> [RhythmTask] {
        tasks.filter { $0.priority == priority }
    }
    
    /// Filter overdue tasks
    var overdueTasks: [RhythmTask] {
        tasks.filter { $0.isOverdue }
    }
    
    /// Filter tasks in their window right now
    var tasksInWindow: [RhythmTask] {
        tasks.filter { $0.isInWindow && $0.status != .done }
    }
    
    /// All unique tags from current tasks
    var allTags: [String] {
        var tags = Set<String>()
        for task in tasks {
            for tag in task.tags ?? [] {
                tags.insert(tag.name)
            }
        }
        return Array(tags).sorted()
    }
}

