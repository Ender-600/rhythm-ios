//
//  TodayTimelineView.swift
//  Rhythm
//
//  24-hour vertical timeline view for a selected day
//  Shows tasks as blocks positioned by their time windows
//

import SwiftUI
import Combine

struct PlanTimeSelection: Identifiable, Equatable {
    let id = UUID()
    let start: Date
    let end: Date

    var durationMinutes: Int {
        max(15, Int(end.timeIntervalSince(start) / 60))
    }
}

private struct TimelineDraftSelection: Equatable {
    let planSelection: PlanTimeSelection
    let offsetY: CGFloat
    let height: CGFloat

    var timeLabel: String {
        planSelection.start.timeRange(to: planSelection.end)
    }
}

struct TodayTimelineView: View {
    let date: Date
    let tasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    var onSnooze: ((RhythmTask) -> Void)?
    var onStart: ((RhythmTask) -> Void)?
    var onCreateSelection: ((PlanTimeSelection) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var activeSelection: TimelineDraftSelection?
    
    // Layout constants
    private let hourHeight: CGFloat = 84
    private let timeColumnWidth: CGFloat = 50
    private let taskLeftPadding: CGFloat = 60
    private let timelineTopPadding: CGFloat = 10
    
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

                    TimelineSelectionSurface(
                        date: date,
                        hourHeight: hourHeight,
                        timeColumnWidth: timeColumnWidth,
                        activeSelection: $activeSelection,
                        onCreateSelection: onCreateSelection
                    )
                    .offset(y: timelineTopPadding)

                    if let activeSelection {
                        TimelineSelectionOverlay(
                            selection: activeSelection,
                            leftPadding: taskLeftPadding,
                            topPadding: timelineTopPadding
                        )
                    }
                    
                    // Task blocks
                    ForEach(tasks) { task in
                        if task.windowStart != nil {
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
                    
                    if Calendar.current.isDateInToday(date) {
                        CurrentTimeIndicator(
                            hourHeight: hourHeight,
                            leftPadding: timeColumnWidth
                        )
                    }
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
        let calendar = Calendar.current
        let referenceDate = calendar.isDateInToday(date)
            ? Date()
            : tasks.first?.windowStart ?? calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date) ?? date
        let targetHour = max(0, calendar.component(.hour, from: referenceDate) - 1)
        withAnimation {
            proxy.scrollTo("hour-\(targetHour)", anchor: .top)
        }
    }
}

// MARK: - Timeline Selection

private struct TimelineSelectionSurface: View {
    let date: Date
    let hourHeight: CGFloat
    let timeColumnWidth: CGFloat
    @Binding var activeSelection: TimelineDraftSelection?
    var onCreateSelection: ((PlanTimeSelection) -> Void)?

    private let snapMinutes = 15
    private let minimumMinutes = 15

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity)
            .frame(height: hourHeight * 24)
            .padding(.leading, timeColumnWidth)
            .gesture(createPlanGesture)
    }

    private var createPlanGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.28, maximumDistance: 18)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag) = value, let drag else { return }

                withAnimation(.snappy(duration: 0.12)) {
                    activeSelection = draftSelection(from: drag.startLocation.y, to: drag.location.y)
                }
            }
            .onEnded { value in
                defer {
                    withAnimation(.snappy(duration: 0.16)) {
                        activeSelection = nil
                    }
                }

                guard case .second(true, let drag) = value, let drag else { return }
                let selection = draftSelection(from: drag.startLocation.y, to: drag.location.y)
                onCreateSelection?(selection.planSelection)
            }
    }

    private func draftSelection(from startY: CGFloat, to currentY: CGFloat) -> TimelineDraftSelection {
        let lowerY = min(startY, currentY)
        let upperY = max(startY, currentY)

        var startMinutes = snappedMinutes(for: lowerY, rounding: .down)
        var endMinutes = snappedMinutes(for: upperY, rounding: .up)

        startMinutes = min(startMinutes, 24 * 60 - minimumMinutes)
        endMinutes = min(max(endMinutes, startMinutes + minimumMinutes), 24 * 60)

        if endMinutes <= startMinutes {
            endMinutes = min(startMinutes + 30, 24 * 60)
        }

        let start = Calendar.current.startOfDay(for: date).adding(minutes: startMinutes)
        let end = Calendar.current.startOfDay(for: date).adding(minutes: endMinutes)
        let offsetY = CGFloat(startMinutes) / 60 * hourHeight
        let height = CGFloat(endMinutes - startMinutes) / 60 * hourHeight

        return TimelineDraftSelection(
            planSelection: PlanTimeSelection(start: start, end: end),
            offsetY: offsetY,
            height: max(height, 35)
        )
    }

    private func snappedMinutes(for y: CGFloat, rounding: FloatingPointRoundingRule) -> Int {
        let clampedY = min(max(y, 0), hourHeight * 24)
        let rawMinutes = Double(clampedY / hourHeight * 60)
        let snapped = (rawMinutes / Double(snapMinutes)).rounded(rounding) * Double(snapMinutes)
        return Int(min(max(snapped, 0), Double(24 * 60)))
    }
}

private struct TimelineSelectionOverlay: View {
    let selection: TimelineDraftSelection
    let leftPadding: CGFloat
    let topPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(selection.timeLabel)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.rhythmTextPrimary)

            if selection.height > 54 {
                Text("New plan")
                    .font(.caption2)
                    .foregroundColor(.rhythmTextSecondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(selection.height - 4, 32), alignment: .topLeading)
        .background(Color.rhythmCoral.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.rhythmCoral, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        )
        .padding(.leading, leftPadding)
        .padding(.trailing, 4)
        .offset(y: selection.offsetY + topPadding)
        .allowsHitTesting(false)
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
                    Text(taskTimeLabel(start: start))
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

    private func taskTimeLabel(start: Date) -> String {
        guard let end = task.windowEnd else { return start.shortTimeString }
        return start.timeRange(to: end)
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
        date: Date(),
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
