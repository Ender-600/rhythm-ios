//
//  TasksViewModel.swift
//  Rhythm
//
//  ViewModel for the prioritized Tasks list
//  All actions logged for learning
//

import Foundation
import SwiftData

@Observable
@MainActor
final class TasksViewModel {
    // MARK: - Published State

    private(set) var tasks: [RhythmTask] = []
    private(set) var isLoading = false

    // Task interaction state
    var selectedTask: RhythmTask?
    var showingSnoozeSheet = false
    var showingCompletionSheet = false
    var showingAddSheet = false

    // MARK: - Dependencies

    private var modelContext: ModelContext?
    private let eventLogService: EventLogService
    private let notificationScheduler: NotificationScheduler

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

        let descriptor = FetchDescriptor<RhythmTask>()

        do {
            tasks = sortedByPrioritization(try context.fetch(descriptor))
            normalizePrioritizationRanks()
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

    // MARK: - Task Creation

    func addTask(
        title: String,
        estimatedMinutes: Int,
        deadline: Date,
        priority: TaskPriority,
        openingAction: String? = nil,
        notes: String? = nil
    ) {
        guard let context = modelContext else {
            showingAddSheet = false
            return
        }

        let task = RhythmTask(
            title: title,
            priority: priority,
            openingAction: openingAction
        )
        task.prioritizationRank = nextTopPrioritizationRank()
        task.estimatedMinutes = estimatedMinutes
        task.deadline = deadline
        task.notes = notes

        context.insert(task)
        eventLogService.logTaskCreated(task)

        try? context.save()

        // Immediately add to tasks array for instant UI update.
        tasks.insert(task, at: 0)
        normalizePrioritizationRanks()

        showingAddSheet = false
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
        let minutesFromNow = Int(start.timeIntervalSinceNow / 60)
        let snoozeOption = SnoozeOption.custom(minutesFromNow)
        task.snooze(to: start, newEnd: end, option: snoozeOption)
        eventLogService.logTaskSnoozed(task, option: snoozeOption, newTime: start)

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

    func moveTasks(from source: IndexSet, to destination: Int) {
        let sourceIndexes = source.sorted()
        guard !sourceIndexes.isEmpty else { return }

        let movingTasks = sourceIndexes.compactMap { index in
            tasks.indices.contains(index) ? tasks[index] : nil
        }
        guard movingTasks.count == sourceIndexes.count else { return }

        var reorderedTasks = tasks.enumerated()
            .filter { !source.contains($0.offset) }
            .map(\.element)

        let removedBeforeDestination = sourceIndexes.filter { $0 < destination }.count
        let insertionIndex = max(0, min(destination - removedBeforeDestination, reorderedTasks.count))

        reorderedTasks.insert(contentsOf: movingTasks, at: insertionIndex)
        tasks = reorderedTasks
        normalizePrioritizationRanks()
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

    // MARK: - Prioritization

    private func sortedByPrioritization(_ tasks: [RhythmTask]) -> [RhythmTask] {
        tasks.sorted { lhs, rhs in
            switch (lhs.prioritizationRank, rhs.prioritizationRank) {
            case let (lhsRank?, rhsRank?) where lhsRank != rhsRank:
                return lhsRank < rhsRank
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return fallbackPrioritizationSort(lhs, rhs)
            }
        }
    }

    private func fallbackPrioritizationSort(_ lhs: RhythmTask, _ rhs: RhythmTask) -> Bool {
        if lhs.priority.sortOrder != rhs.priority.sortOrder {
            return lhs.priority.sortOrder < rhs.priority.sortOrder
        }

        switch (lhs.windowStart, rhs.windowStart) {
        case let (lhsStart?, rhsStart?) where lhsStart != rhsStart:
            return lhsStart < rhsStart
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            return lhs.createdAt < rhs.createdAt
        }
    }

    private func nextTopPrioritizationRank() -> Double {
        let topRank = tasks.compactMap(\.prioritizationRank).min() ?? 0
        return topRank - 1
    }

    private func normalizePrioritizationRanks() {
        var didChange = false

        for (index, task) in tasks.enumerated() {
            let rank = Double(index)
            if task.prioritizationRank != rank {
                task.prioritizationRank = rank
                task.markDirty()
                didChange = true
            }
        }

        if didChange {
            try? modelContext?.save()
        }
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
