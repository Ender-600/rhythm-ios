//
//  TimeWindowCard.swift
//  Rhythm
//
//  Individual time block card for the plan view
//

import SwiftUI

struct TimeWindowCard: View {
    let task: RhythmTask
    var isCompact: Bool = false
    var onTap: (() -> Void)?
    var onSnooze: (() -> Void)?
    var onStart: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: isCompact ? 4 : 8) {
                // Header with time and priority
                HStack {
                    if let start = task.windowStart {
                        Text(start.shortTimeString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                    
                    Spacer()
                    
                    PriorityChip(priority: task.priority, isCompact: true)
                }
                
                // Title
                Text(task.title)
                    .font(isCompact ? .subheadline : .body)
                    .fontWeight(.medium)
                    .foregroundColor(.rhythmTextPrimary)
                    .lineLimit(isCompact ? 1 : 2)
                
                // Opening action (if not compact)
                if !isCompact, let opening = task.openingAction {
                    Text("→ \(opening)")
                        .font(.caption)
                        .foregroundColor(.rhythmSage)
                        .lineLimit(1)
                }
                
                // Tags
                if !isCompact, let tags = task.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(3)) { tag in
                            Text("#\(tag.name)")
                                .font(.caption2)
                                .foregroundColor(.rhythmTextMuted)
                        }
                    }
                }
                
                // Actions (if in window)
                if task.isInWindow && task.status == .notStarted && !isCompact {
                    HStack(spacing: 8) {
                        GentleTextButton(title: "Start", icon: "play.fill") {
                            onStart?()
                        }
                        
                        Spacer()
                        
                        GentleTextButton(title: "Later", icon: "clock", color: .rhythmTextSecondary) {
                            onSnooze?()
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Status indicator
                if task.status == .inProgress {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.rhythmCoral)
                            .frame(width: 6, height: 6)
                        Text("In progress")
                            .font(.caption2)
                            .foregroundColor(.rhythmCoral)
                    }
                }
                
                // Snooze count
                if task.snoozeCount > 0 && !isCompact {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text("Snoozed \(task.snoozeCount)x")
                            .font(.caption2)
                    }
                    .foregroundColor(.rhythmTextMuted)
                }
            }
            .padding(isCompact ? 10 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: task.isInWindow ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var cardBackground: Color {
        if task.status == .inProgress {
            return Color.rhythmCoral.opacity(0.1)
        } else if task.isInWindow {
            return Color.rhythmAmber.opacity(0.1)
        }
        return Color.rhythmCard(for: colorScheme)
    }
    
    private var borderColor: Color {
        if task.status == .inProgress {
            return .rhythmCoral
        } else if task.isInWindow {
            return .rhythmAmber
        }
        return .clear
    }
}

// MARK: - Compact Time Block (for timeline)

struct CompactTimeBlock: View {
    let task: RhythmTask
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(task.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if height > 30, let start = task.windowStart {
                Text(start.shortTimeString)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height)
        .background(task.priority.color.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        TimeWindowCard(
            task: {
                let task = RhythmTask(
                    title: "Send weekly report email",
                    windowStart: Date(),
                    windowEnd: Date().adding(hours: 1),
                    priority: .normal,
                    openingAction: "Open email and find the template"
                )
                return task
            }()
        )
        
        TimeWindowCard(
            task: {
                let task = RhythmTask(
                    title: "Team meeting",
                    windowStart: Date().adding(hours: 2),
                    windowEnd: Date().adding(hours: 3),
                    priority: .urgent
                )
                task.start()
                return task
            }()
        )
        
        TimeWindowCard(
            task: RhythmTask(
                title: "Quick task",
                windowStart: Date().adding(hours: 4),
                priority: .low
            ),
            isCompact: true
        )
    }
    .padding()
}

