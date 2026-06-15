//
//  TaskRowView.swift
//  Rhythm
//
//  Individual task row for list and board views
//

import SwiftUI

struct TaskRowView: View {
    let task: RhythmTask
    var onTap: (() -> Void)?
    var onStart: (() -> Void)?
    var onComplete: (() -> Void)?
    var onSnooze: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(alignment: .top, spacing: 12) {
                // Status indicator
                statusIndicator
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.rhythmTextPrimary)
                        .strikethrough(task.status == .done)
                        .lineLimit(2)
                    
                    // Window time
                    if let description = task.windowDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                    
                    // Tags
                    if let tags = task.tags, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(tags.prefix(3)) { tag in
                                Text("#\(tag.name)")
                                    .font(.caption2)
                                    .foregroundColor(.rhythmTextMuted)
                            }
                        }
                    }
                    
                    // Meta info
                    HStack(spacing: 8) {
                        // Priority
                        HStack(spacing: 2) {
                            Image(systemName: "flag.fill")
                                .font(.caption2)
                            Text(task.priority.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(task.priority.color)
                        
                        // Snooze count
                        if task.snoozeCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption2)
                                Text("\(task.snoozeCount)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.rhythmTextMuted)
                        }
                        
                        // Overdue indicator
                        if task.isOverdue {
                            Text("Overdue")
                                .font(.caption2)
                                .foregroundColor(.rhythmError)
                        }
                    }
                }
                
                Spacer()
                
                // Quick actions
                if task.status != .done {
                    quickActions
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.rhythmCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var statusIndicator: some View {
        Button(action: {
            if task.status == .done {
                // Could implement "undo complete" here
            } else {
                onComplete?()
            }
        }) {
            Image(systemName: task.status.icon)
                .font(.title3)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .notStarted:
            return .rhythmTextMuted
        case .inProgress:
            return .rhythmCoral
        case .done:
            return .rhythmSuccess
        }
    }
    
    private var quickActions: some View {
        HStack(spacing: 8) {
            if task.status == .notStarted {
                GentleIconButton(icon: "play.fill", size: 32, style: .primary) {
                    onStart?()
                }
            } else if task.status == .inProgress {
                GentleIconButton(icon: "checkmark", size: 32, style: .primary) {
                    onComplete?()
                }
            }
            
            GentleIconButton(icon: "clock", size: 32, style: .subtle) {
                onSnooze?()
            }
        }
    }
}

// MARK: - Compact Task Row (for board view)

struct CompactTaskRow: View {
    let task: RhythmTask
    var onTap: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.rhythmTextPrimary)
                    .strikethrough(task.status == .done)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    // Priority dot
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 6, height: 6)
                    
                    // Time
                    if let start = task.windowStart {
                        Text(start.shortTimeString)
                            .font(.caption2)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Snooze count
                    if task.snoozeCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("\(task.snoozeCount)")
                        }
                        .font(.caption2)
                        .foregroundColor(.rhythmTextMuted)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.rhythmCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TaskRowView(
            task: RhythmTask(
                title: "Send weekly report to the team",
                windowStart: Date(),
                windowEnd: Date().adding(hours: 1),
                priority: .urgent
            )
        )
        
        TaskRowView(
            task: {
                let t = RhythmTask(title: "Review PRs", priority: .normal)
                t.start()
                return t
            }()
        )
        
        TaskRowView(
            task: {
                let t = RhythmTask(title: "Clean desk", priority: .low)
                t.complete()
                return t
            }()
        )
        
        CompactTaskRow(
            task: RhythmTask(title: "Quick task", priority: .normal)
        )
    }
    .padding()
}

