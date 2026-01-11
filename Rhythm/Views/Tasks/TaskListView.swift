//
//  TaskListView.swift
//  Rhythm
//
//  Simple list view of all tasks
//

import SwiftUI

struct TaskListView: View {
    let tasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    var onTaskStart: ((RhythmTask) -> Void)?
    var onTaskComplete: ((RhythmTask) -> Void)?
    var onTaskSnooze: ((RhythmTask) -> Void)?
    var onTaskDelete: ((RhythmTask) -> Void)?
    
    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(tasks) { task in
                TaskRowView(
                    task: task,
                    onTap: { onTaskTap?(task) },
                    onStart: { onTaskStart?(task) },
                    onComplete: { onTaskComplete?(task) },
                    onSnooze: { onTaskSnooze?(task) }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onTaskDelete?(task)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    if task.status != .done {
                        Button {
                            onTaskSnooze?(task)
                        } label: {
                            Label("Snooze", systemImage: "clock")
                        }
                        .tint(.rhythmAmber)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if task.status == .notStarted {
                        Button {
                            onTaskStart?(task)
                        } label: {
                            Label("Start", systemImage: "play.fill")
                        }
                        .tint(.rhythmCoral)
                    } else if task.status == .inProgress {
                        Button {
                            onTaskComplete?(task)
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(.rhythmSuccess)
                    }
                }
            }
        }
    }
}

// MARK: - Grouped Task List

struct GroupedTaskListView: View {
    let tasks: [RhythmTask]
    let groupBy: GroupOption
    var onTaskTap: ((RhythmTask) -> Void)?
    var onTaskStart: ((RhythmTask) -> Void)?
    var onTaskComplete: ((RhythmTask) -> Void)?
    var onTaskSnooze: ((RhythmTask) -> Void)?
    
    enum GroupOption {
        case status
        case priority
        case date
    }
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(groupedTasks, id: \.0) { group, tasks in
                VStack(alignment: .leading, spacing: 10) {
                    // Group header
                    Text(group)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.rhythmTextSecondary)
                        .padding(.horizontal, 4)
                    
                    // Tasks in group
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            onTap: { onTaskTap?(task) },
                            onStart: { onTaskStart?(task) },
                            onComplete: { onTaskComplete?(task) },
                            onSnooze: { onTaskSnooze?(task) }
                        )
                    }
                }
            }
        }
    }
    
    private var groupedTasks: [(String, [RhythmTask])] {
        switch groupBy {
        case .status:
            return groupByStatus()
        case .priority:
            return groupByPriority()
        case .date:
            return groupByDate()
        }
    }
    
    private func groupByStatus() -> [(String, [RhythmTask])] {
        let grouped = Dictionary(grouping: tasks) { $0.status }
        return [
            (TaskStatus.inProgress.displayName, grouped[.inProgress] ?? []),
            (TaskStatus.notStarted.displayName, grouped[.notStarted] ?? []),
            (TaskStatus.done.displayName, grouped[.done] ?? [])
        ].filter { !$0.1.isEmpty }
    }
    
    private func groupByPriority() -> [(String, [RhythmTask])] {
        let grouped = Dictionary(grouping: tasks) { $0.priority }
        return [
            (TaskPriority.urgent.displayName, grouped[.urgent] ?? []),
            (TaskPriority.normal.displayName, grouped[.normal] ?? []),
            (TaskPriority.low.displayName, grouped[.low] ?? [])
        ].filter { !$0.1.isEmpty }
    }
    
    private func groupByDate() -> [(String, [RhythmTask])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: tasks) { task -> String in
            guard let start = task.windowStart else { return "No date" }
            if calendar.isDateInToday(start) { return "Today" }
            if calendar.isDateInTomorrow(start) { return "Tomorrow" }
            if start < Date() { return "Overdue" }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: start)
        }
        
        // Sort by date
        let sortOrder = ["Overdue", "Today", "Tomorrow", "No date"]
        return grouped.sorted { a, b in
            let aIndex = sortOrder.firstIndex(of: a.key) ?? 100
            let bIndex = sortOrder.firstIndex(of: b.key) ?? 100
            return aIndex < bIndex
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        TaskListView(
            tasks: [
                RhythmTask(title: "Task 1", priority: .urgent),
                RhythmTask(title: "Task 2", priority: .normal),
                {
                    let t = RhythmTask(title: "Task 3", priority: .low)
                    t.complete()
                    return t
                }()
            ]
        )
        .padding()
    }
}

