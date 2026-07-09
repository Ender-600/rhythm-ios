//
//  WeekAgendaView.swift
//  Rhythm
//
//  Seven-day agenda used as the middle calendar zoom level.
//

import SwiftUI

struct WeekAgendaView: View {
    let dates: [Date]
    let focusedDate: Date
    let tasksProvider: (Date) -> [RhythmTask]
    var onDayTap: ((Date) -> Void)?
    var onTaskTap: ((RhythmTask) -> Void)?
    var onSnooze: ((RhythmTask) -> Void)?
    var onStart: ((RhythmTask) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var didScrollToFocus = false

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = min(max(geometry.size.width * 0.42, 148), 220)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(dates, id: \.self) { date in
                            AgendaDayColumnView(
                                date: date,
                                tasks: tasksProvider(date),
                                width: columnWidth,
                                isFocused: Calendar.current.isDate(date, inSameDayAs: focusedDate),
                                onDayTap: { onDayTap?(date) },
                                onTaskTap: onTaskTap,
                                onSnooze: onSnooze,
                                onStart: onStart
                            )
                            .id(dateId(for: date))
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .onAppear {
                    if !didScrollToFocus {
                        scrollToFocusedDate(proxy: proxy)
                        didScrollToFocus = true
                    }
                }
            }
        }
    }

    private func dateId(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func scrollToFocusedDate(proxy: ScrollViewProxy) {
        let focusedId = dateId(for: focusedDate)

        // Small delay to ensure the scroll view is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.none) {
                proxy.scrollTo(focusedId, anchor: .center)
            }
        }
    }
}

// MARK: - Day Column View

private struct AgendaDayColumnView: View {
    let date: Date
    let tasks: [RhythmTask]
    let width: CGFloat
    let isFocused: Bool
    var onDayTap: (() -> Void)?
    var onTaskTap: ((RhythmTask) -> Void)?
    var onSnooze: ((RhythmTask) -> Void)?
    var onStart: ((RhythmTask) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }

    private var isPast: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day header
            dayHeader

            // Divider
            Divider()
                .background(Color.rhythmTextMuted.opacity(0.3))

            // Tasks list
            ScrollView {
                LazyVStack(spacing: 10) {
                    if tasks.isEmpty {
                        emptyDayState
                    } else {
                        ForEach(tasks) { task in
                            AgendaDayTaskCard(
                                task: task,
                                onTap: { onTaskTap?(task) },
                                onSnooze: { onSnooze?(task) },
                                onStart: { onStart?(task) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
        }
        .frame(width: width)
        .background(columnBackground)
        .overlay(
            Rectangle()
                .fill(Color.rhythmTextMuted.opacity(0.15))
                .frame(width: 1),
            alignment: .trailing
        )
    }

    private var dayHeader: some View {
        Button(action: { onDayTap?() }) {
            VStack(spacing: 2) {
                Text(dayLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .rhythmCoral : .rhythmTextSecondary)

                Text("\(date.day)")
                    .font(.title2)
                    .fontWeight(isToday || isFocused ? .bold : .semibold)
                    .foregroundColor(isToday ? .rhythmCoral : (isPast ? .rhythmTextMuted : .rhythmTextPrimary))

                Text(date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundColor(.rhythmTextMuted)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(headerBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the minute-by-minute day timeline")
    }

    private var dayLabel: String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            return date.weekdayShort
        }
    }

    private var headerBackground: Color {
        if isToday {
            return Color.rhythmCoral.opacity(0.1)
        } else if isFocused {
            return Color.rhythmAmber.opacity(0.1)
        }
        return Color.clear
    }

    private var columnBackground: Color {
        if isPast {
            return Color.rhythmTextMuted.opacity(0.05)
        }
        return Color.clear
    }

    private var emptyDayState: some View {
        VStack(spacing: 8) {
            Image(systemName: isPast ? "checkmark.circle" : "sun.min")
                .font(.system(size: 24))
                .foregroundColor(.rhythmTextMuted)

            Text(isPast ? "All done" : "Free day")
                .font(.caption)
                .foregroundColor(.rhythmTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Day Task Card

private struct AgendaDayTaskCard: View {
    let task: RhythmTask
    var onTap: (() -> Void)?
    var onSnooze: (() -> Void)?
    var onStart: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 6) {
                // Time
                if let start = task.windowStart {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(start.shortTimeString)
                            .font(.caption)
                    }
                    .foregroundColor(.rhythmTextSecondary)
                }

                // Title
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.rhythmTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Priority indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 6, height: 6)

                    Text(task.priority.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.rhythmTextMuted)

                    Spacer()

                    // Status indicator
                    if task.status == .inProgress {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.rhythmCoral)
                                .frame(width: 5, height: 5)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(.rhythmCoral)
                        }
                    }
                }

                // Quick actions (if in window)
                if task.isInWindow && task.status == .notStarted {
                    HStack(spacing: 12) {
                        SmallActionButton(title: "Start", icon: "play.fill") {
                            onStart?()
                        }

                        SmallActionButton(title: "Later", icon: "clock", color: .rhythmTextSecondary) {
                            onSnooze?()
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: task.isInWindow ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: Color {
        if task.status == .inProgress {
            return Color.rhythmCoral.opacity(0.12)
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

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Generate date range
    let dateRange: [Date] = (0..<7).compactMap { offset in
        calendar.date(byAdding: .day, value: offset, to: today)
    }

    // Sample tasks provider
    let tasksProvider: (Date) -> [RhythmTask] = { date in
        if calendar.isDateInToday(date) {
            return [
                RhythmTask(
                    title: "Morning standup",
                    windowStart: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date),
                    windowEnd: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: date),
                    priority: .urgent
                ),
                RhythmTask(
                    title: "Review PRs",
                    windowStart: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date),
                    windowEnd: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: date),
                    priority: .normal
                )
            ]
        } else if calendar.isDateInTomorrow(date) {
            return [
                RhythmTask(
                    title: "Team planning",
                    windowStart: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: date),
                    windowEnd: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: date),
                    priority: .normal
                )
            ]
        }
        return []
    }

    return WeekAgendaView(
        dates: dateRange,
        focusedDate: Date(),
        tasksProvider: tasksProvider
    )
    .frame(height: 500)
}
