//
//  PlanSketchView.swift
//  Rhythm
//
//  Visual "plan sketch" - flexible, not a rigid calendar
//  Shows time windows with buffers in a friendly way
//

import SwiftUI

struct PlanSketchView: View {
    let tasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    var onSnooze: ((RhythmTask) -> Void)?
    var onStart: ((RhythmTask) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Currently active
            if let active = tasks.first(where: { $0.status == .inProgress }) {
                sectionHeader(Copy.Plan.inProgress, icon: "play.circle.fill", color: .rhythmCoral)
                
                TimeWindowCard(
                    task: active,
                    onTap: { onTaskTap?(active) },
                    onSnooze: { onSnooze?(active) },
                    onStart: { onStart?(active) }
                )
            }
            
            // Next up
            if let next = tasks.first(where: { $0.status == .notStarted && $0.isInWindow }) {
                sectionHeader(Copy.Plan.nextUp, icon: "arrow.right.circle", color: .rhythmAmber)
                
                TimeWindowCard(
                    task: next,
                    onTap: { onTaskTap?(next) },
                    onSnooze: { onSnooze?(next) },
                    onStart: { onStart?(next) }
                )
            }
            
            // Coming soon (future windows)
            let upcoming = tasks.filter { task in
                task.status == .notStarted &&
                !task.isInWindow &&
                task.windowStart != nil &&
                task.windowStart! > Date()
            }
            
            if !upcoming.isEmpty {
                sectionHeader(Copy.Plan.comingSoon, icon: "clock", color: .rhythmTextSecondary)
                
                VStack(spacing: 10) {
                    ForEach(upcoming.prefix(5)) { task in
                        TimeWindowCard(
                            task: task,
                            isCompact: true,
                            onTap: { onTaskTap?(task) },
                            onSnooze: { onSnooze?(task) }
                        )
                    }
                }
            }
            
            // Empty state
            if tasks.isEmpty {
                emptyState
            }
        }
    }
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.rhythmTextSecondary)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max")
                .font(.system(size: 40))
                .foregroundColor(.rhythmAmber)
            
            Text(Copy.Plan.emptyDay)
                .font(.headline)
                .foregroundColor(.rhythmTextPrimary)
            
            Text("Add something when you're ready")
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Priority Sections View

struct PrioritySectionsView: View {
    let urgentTasks: [RhythmTask]
    let normalTasks: [RhythmTask]
    let lowTasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !urgentTasks.isEmpty {
                prioritySection(
                    title: Copy.Plan.urgentSection,
                    tasks: urgentTasks,
                    color: .rhythmCoral
                )
            }
            
            if !normalTasks.isEmpty {
                prioritySection(
                    title: Copy.Plan.normalSection,
                    tasks: normalTasks,
                    color: .rhythmAmber
                )
            }
            
            if !lowTasks.isEmpty {
                prioritySection(
                    title: Copy.Plan.lowSection,
                    tasks: lowTasks,
                    color: .rhythmSage
                )
            }
        }
    }
    
    private func prioritySection(title: String, tasks: [RhythmTask], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 16)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextSecondary)
                
                Text("(\(tasks.count))")
                    .font(.caption)
                    .foregroundColor(.rhythmTextMuted)
            }
            
            ForEach(tasks) { task in
                TimeWindowCard(
                    task: task,
                    isCompact: true,
                    onTap: { onTaskTap?(task) }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PlanSketchView(
            tasks: [
                {
                    let t = RhythmTask(title: "Morning standup", windowStart: Date(), windowEnd: Date().adding(minutes: 30), priority: .urgent)
                    t.start()
                    return t
                }(),
                RhythmTask(title: "Review PRs", windowStart: Date().adding(hours: 1), windowEnd: Date().adding(hours: 2), priority: .normal),
                RhythmTask(title: "Lunch break", windowStart: Date().adding(hours: 3), windowEnd: Date().adding(hours: 4), priority: .low)
            ]
        )
        .padding()
    }
}

