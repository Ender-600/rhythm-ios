//
//  TaskBoardView.swift
//  Rhythm
//
//  Kanban-style board view with three columns
//

import SwiftUI

struct TaskBoardView: View {
    let notStartedTasks: [RhythmTask]
    let inProgressTasks: [RhythmTask]
    let doneTasks: [RhythmTask]
    
    var onTaskTap: ((RhythmTask) -> Void)?
    var onTaskStart: ((RhythmTask) -> Void)?
    var onTaskComplete: ((RhythmTask) -> Void)?
    var onTaskSnooze: ((RhythmTask) -> Void)?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                // Not Started
                BoardColumn(
                    title: Copy.Tasks.notStartedColumn,
                    count: notStartedTasks.count,
                    color: .rhythmTextSecondary
                ) {
                    ForEach(notStartedTasks) { task in
                        BoardTaskCard(
                            task: task,
                            onTap: { onTaskTap?(task) },
                            primaryAction: {
                                onTaskStart?(task)
                            },
                            primaryActionIcon: "play.fill",
                            secondaryAction: {
                                onTaskSnooze?(task)
                            }
                        )
                    }
                }
                
                // In Progress
                BoardColumn(
                    title: Copy.Tasks.inProgressColumn,
                    count: inProgressTasks.count,
                    color: .rhythmCoral
                ) {
                    ForEach(inProgressTasks) { task in
                        BoardTaskCard(
                            task: task,
                            onTap: { onTaskTap?(task) },
                            primaryAction: {
                                onTaskComplete?(task)
                            },
                            primaryActionIcon: "checkmark",
                            secondaryAction: {
                                onTaskSnooze?(task)
                            }
                        )
                    }
                }
                
                // Done
                BoardColumn(
                    title: Copy.Tasks.doneColumn,
                    count: doneTasks.count,
                    color: .rhythmSuccess
                ) {
                    ForEach(doneTasks.prefix(10)) { task in
                        CompactTaskRow(task: task) {
                            onTaskTap?(task)
                        }
                        .opacity(0.7)
                    }
                    
                    if doneTasks.count > 10 {
                        Text("+ \(doneTasks.count - 10) more")
                            .font(.caption)
                            .foregroundColor(.rhythmTextMuted)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Board Column

struct BoardColumn<Content: View>: View {
    let title: String
    let count: Int
    let color: Color
    @ViewBuilder let content: () -> Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextSecondary)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.rhythmTextMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.rhythmChip(for: colorScheme))
                    .clipShape(Capsule())
            }
            
            // Tasks
            VStack(spacing: 8) {
                content()
            }
            
            if count == 0 {
                Text("Nothing here")
                    .font(.caption)
                    .foregroundColor(.rhythmTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .frame(width: 280)
        .padding(12)
        .background(Color.rhythmCard(for: colorScheme).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Board Task Card

struct BoardTaskCard: View {
    let task: RhythmTask
    var onTap: (() -> Void)?
    var primaryAction: (() -> Void)?
    var primaryActionIcon: String = "play.fill"
    var secondaryAction: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.rhythmTextPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Opening action
                if let opening = task.openingAction {
                    Text("→ \(opening)")
                        .font(.caption)
                        .foregroundColor(.rhythmSage)
                        .lineLimit(1)
                }
                
                // Meta row
                HStack {
                    // Priority
                    HStack(spacing: 2) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                        Text(task.priority.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(task.priority.color)
                    
                    // Time
                    if let start = task.windowStart {
                        Text("·")
                            .foregroundColor(.rhythmTextMuted)
                        Text(start.shortTimeString)
                            .font(.caption2)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Snooze
                    if task.snoozeCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("\(task.snoozeCount)")
                        }
                        .font(.caption2)
                        .foregroundColor(.rhythmTextMuted)
                    }
                }
                
                // Actions
                HStack(spacing: 8) {
                    Button(action: { primaryAction?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: primaryActionIcon)
                            Text(primaryActionIcon == "play.fill" ? "Start" : "Done")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.rhythmCoral)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: { secondaryAction?() }) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.rhythmTextSecondary)
                            .padding(6)
                            .background(Color.rhythmChip(for: colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(12)
            .background(Color.rhythmCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TaskBoardView(
        notStartedTasks: [
            RhythmTask(title: "Send emails", priority: .urgent),
            RhythmTask(title: "Review code", priority: .normal)
        ],
        inProgressTasks: [
            {
                let t = RhythmTask(title: "Write documentation", priority: .normal)
                t.start()
                return t
            }()
        ],
        doneTasks: [
            {
                let t = RhythmTask(title: "Morning standup", priority: .urgent)
                t.complete()
                return t
            }()
        ]
    )
}

