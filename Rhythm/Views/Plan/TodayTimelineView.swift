//
//  TodayTimelineView.swift
//  Rhythm
//
//  24-hour vertical timeline view for today's tasks
//  Shows tasks as blocks positioned by their time windows
//

import SwiftUI
import Combine

struct TodayTimelineView: View {
    let tasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    var onSnooze: ((RhythmTask) -> Void)?
    var onStart: ((RhythmTask) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Layout constants
    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 50
    private let taskLeftPadding: CGFloat = 60
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Time grid background
                    TimeGridBackground(
                        hourHeight: hourHeight,
                        timeColumnWidth: timeColumnWidth,
                        colorScheme: colorScheme
                    )
                    
                    // Task blocks
                    ForEach(tasks) { task in
                        if let startTime = task.windowStart {
                            TaskTimeBlock(
                                task: task,
                                hourHeight: hourHeight,
                                leftPadding: taskLeftPadding,
                                onTap: { onTaskTap?(task) },
                                onSnooze: { onSnooze?(task) },
                                onStart: { onStart?(task) }
                            )
                        }
                    }
                    
                    // Current time indicator
                    CurrentTimeIndicator(
                        hourHeight: hourHeight,
                        leftPadding: timeColumnWidth
                    )
                }
                .frame(height: hourHeight * 24 + 20) // 24 hours + padding
                .padding(.trailing, 16)
            }
            .onAppear {
                scrollToCurrentTime(proxy: proxy)
            }
        }
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let currentHour = Calendar.current.component(.hour, from: Date())
        // Scroll to an hour before current time for better context
        let targetHour = max(0, currentHour - 1)
        withAnimation {
            proxy.scrollTo("hour-\(targetHour)", anchor: .top)
        }
    }
}

// MARK: - Time Grid Background

struct TimeGridBackground: View {
    let hourHeight: CGFloat
    let timeColumnWidth: CGFloat
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    // Time label
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundColor(.rhythmTextMuted)
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.trailing, 8)
                    
                    // Hour line
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.rhythmTextMuted.opacity(0.3))
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
                .id("hour-\(hour)")
            }
        }
        .padding(.top, 10)
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
}

// MARK: - Task Time Block

struct TaskTimeBlock: View {
    let task: RhythmTask
    let hourHeight: CGFloat
    let leftPadding: CGFloat
    var onTap: (() -> Void)?
    var onSnooze: (() -> Void)?
    var onStart: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let position = calculatePosition()
        
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 4) {
                // Time
                if let start = task.windowStart {
                    Text(start.shortTimeString)
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.8))
                }
                
                // Title
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .lineLimit(position.height > 50 ? 2 : 1)
                
                // Opening action (if tall enough)
                if position.height > 70, let opening = task.openingAction {
                    Text("→ \(opening)")
                        .font(.caption2)
                        .foregroundColor(textColor.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                // Action buttons (if in window and tall enough)
                if task.isInWindow && task.status == .notStarted && position.height > 80 {
                    HStack(spacing: 8) {
                        SmallActionButton(title: "Start", icon: "play.fill") {
                            onStart?()
                        }
                        
                        SmallActionButton(title: "Later", icon: "clock", color: textColor.opacity(0.7)) {
                            onSnooze?()
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: max(position.height - 4, 30))
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: task.isInWindow ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
        .padding(.leading, leftPadding)
        .padding(.trailing, 4)
        .offset(y: position.offsetY + 10) // +10 for top padding
    }
    
    private func calculatePosition() -> (offsetY: CGFloat, height: CGFloat) {
        guard let start = task.windowStart else {
            return (0, hourHeight)
        }
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: start)
        let startMinute = calendar.component(.minute, from: start)
        
        let offsetY = CGFloat(startHour) * hourHeight + CGFloat(startMinute) / 60.0 * hourHeight
        
        var height: CGFloat = hourHeight
        if let end = task.windowEnd {
            let duration = end.timeIntervalSince(start)
            height = CGFloat(duration / 3600.0) * hourHeight
        }
        
        // Minimum height
        height = max(height, 35)
        
        return (offsetY, height)
    }
    
    private var backgroundColor: Color {
        if task.status == .inProgress {
            return task.priority.color.opacity(0.25)
        } else if task.isInWindow {
            return task.priority.color.opacity(0.2)
        }
        return task.priority.color.opacity(0.15)
    }
    
    private var borderColor: Color {
        if task.status == .inProgress || task.isInWindow {
            return task.priority.color
        }
        return .clear
    }
    
    private var textColor: Color {
        .rhythmTextPrimary
    }
}

// MARK: - Current Time Indicator

struct CurrentTimeIndicator: View {
    let hourHeight: CGFloat
    let leftPadding: CGFloat
    
    @State private var currentTime = Date()
    
    // Update timer
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let offset = calculateOffset()
        
        HStack(spacing: 0) {
            // Left spacer for time column
            Color.clear
                .frame(width: leftPadding - 4)
            
            // Red dot
            Circle()
                .fill(Color.rhythmCoral)
                .frame(width: 8, height: 8)
            
            // Red line
            Rectangle()
                .fill(Color.rhythmCoral)
                .frame(height: 2)
        }
        .offset(y: offset + 10) // +10 for top padding
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func calculateOffset() -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        return CGFloat(hour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }
}

// MARK: - Small Action Button

struct SmallActionButton: View {
    let title: String
    let icon: String
    var color: Color = .rhythmCoral
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
        }
    }
}

// MARK: - Empty Timeline State

struct EmptyTimelineState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sun.max")
                .font(.system(size: 40))
                .foregroundColor(.rhythmAmber)
            
            Text(Copy.Plan.emptyDay)
                .font(.headline)
                .foregroundColor(.rhythmTextPrimary)
            
            Text("Your timeline is clear")
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Preview

#Preview {
    TodayTimelineView(
        tasks: [
            {
                let t = RhythmTask(
                    title: "Morning standup",
                    windowStart: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
                    windowEnd: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date()),
                    priority: .urgent
                )
                return t
            }(),
            RhythmTask(
                title: "Review PRs",
                windowStart: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()),
                windowEnd: Calendar.current.date(bySettingHour: 11, minute: 30, second: 0, of: Date()),
                priority: .normal,
                openingAction: "Open GitHub and check notifications"
            ),
            RhythmTask(
                title: "Lunch break",
                windowStart: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date()),
                windowEnd: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: Date()),
                priority: .low
            ),
            RhythmTask(
                title: "Team meeting",
                windowStart: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()),
                windowEnd: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()),
                priority: .urgent
            )
        ]
    )
    .padding()
}
