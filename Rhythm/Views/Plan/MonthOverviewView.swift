//
//  MonthOverviewView.swift
//  Rhythm
//
//  Month calendar grid overview showing task density
//  Scroll up/down to see previous/next months
//

import SwiftUI

struct MonthOverviewView: View {
    let months: [Date]
    let tasksForMonth: (Date) -> [Date: [RhythmTask]]
    var onDayTap: ((Date) -> Void)?
    var onTaskTap: ((RhythmTask) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrolledToCurrentMonth = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(months, id: \.self) { month in
                        MonthGridView(
                            month: month,
                            tasksByDate: tasksForMonth(month),
                            onDayTap: onDayTap,
                            onTaskTap: onTaskTap
                        )
                        .id(monthId(for: month))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear {
                if !scrolledToCurrentMonth {
                    scrollToCurrentMonth(proxy: proxy)
                    scrolledToCurrentMonth = true
                }
            }
        }
    }
    
    private func monthId(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    
    private func scrollToCurrentMonth(proxy: ScrollViewProxy) {
        let currentMonth = Calendar.current.startOfMonth(for: Date())
        let currentMonthId = monthId(for: currentMonth)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.none) {
                proxy.scrollTo(currentMonthId, anchor: .top)
            }
        }
    }
}

// MARK: - Month Grid View

struct MonthGridView: View {
    let month: Date
    let tasksByDate: [Date: [RhythmTask]]
    var onDayTap: ((Date) -> Void)?
    var onTaskTap: ((RhythmTask) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Month header
            HStack {
                Text(month.monthYearString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextPrimary)
                
                Spacer()
                
                // Task count for the month
                let totalTasks = tasksByDate.values.reduce(0) { $0 + $1.count }
                if totalTasks > 0 {
                    Text("\(totalTasks) tasks")
                        .font(.caption)
                        .foregroundColor(.rhythmTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.rhythmChip(for: colorScheme))
                        .clipShape(Capsule())
                }
            }
            
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.rhythmTextMuted)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading empty cells for alignment
                ForEach(0..<leadingEmptyCells, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
                
                // Day cells
                ForEach(daysInMonth, id: \.self) { date in
                    DayCellView(
                        date: date,
                        tasks: tasksByDate[Calendar.current.startOfDay(for: date)] ?? [],
                        onTap: { onDayTap?(date) },
                        onTaskTap: onTaskTap
                    )
                }
                
                // Trailing empty cells
                ForEach(0..<trailingEmptyCells, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(16)
        .background(Color.rhythmCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var daysInMonth: [Date] {
        Calendar.current.datesInMonth(for: month)
    }
    
    private var leadingEmptyCells: Int {
        let firstDay = Calendar.current.startOfMonth(for: month)
        return firstDay.weekdayIndex - 1 // weekdayIndex is 1-based (1 = Sunday)
    }
    
    private var trailingEmptyCells: Int {
        let totalCells = leadingEmptyCells + daysInMonth.count
        let remainder = totalCells % 7
        return remainder == 0 ? 0 : 7 - remainder
    }
}

// MARK: - Day Cell View

struct DayCellView: View {
    let date: Date
    let tasks: [RhythmTask]
    var onTap: (() -> Void)?
    var onTaskTap: ((RhythmTask) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingTasks = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isPast: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        Button(action: { 
            if !tasks.isEmpty {
                showingTasks = true
            }
            onTap?()
        }) {
            VStack(spacing: 2) {
                // Day number
                Text("\(date.day)")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(dayTextColor)
                
                // Task indicators
                if !tasks.isEmpty {
                    taskIndicators
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.rhythmCoral : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingTasks) {
            DayTasksSheet(
                date: date,
                tasks: tasks,
                onTaskTap: onTaskTap
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private var dayTextColor: Color {
        if isToday {
            return .rhythmCoral
        } else if isPast {
            return .rhythmTextMuted
        }
        return .rhythmTextPrimary
    }
    
    private var cellBackground: Color {
        if isToday {
            return Color.rhythmCoral.opacity(0.1)
        } else if !tasks.isEmpty {
            return Color.rhythmAmber.opacity(0.08)
        }
        return Color.clear
    }
    
    @ViewBuilder
    private var taskIndicators: some View {
        let taskCount = tasks.count
        
        if taskCount <= 3 {
            // Show dots for few tasks
            HStack(spacing: 2) {
                ForEach(tasks.prefix(3)) { task in
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 4, height: 4)
                }
            }
        } else {
            // Show count for many tasks
            Text("+\(taskCount)")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.rhythmTextSecondary)
        }
    }
}

// MARK: - Day Tasks Sheet

struct DayTasksSheet: View {
    let date: Date
    let tasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(tasks) { task in
                        Button(action: {
                            onTaskTap?(task)
                            dismiss()
                        }) {
                            DayTaskRow(task: task)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color.rhythmBackground(for: colorScheme))
            .navigationTitle(date.isToday ? "Today" : date.shortMonthDay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Day Task Row

struct DayTaskRow: View {
    let task: RhythmTask
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(task.priority.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.rhythmTextPrimary)
                
                // Time
                if let start = task.windowStart {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        if let end = task.windowEnd {
                            Text(start.timeRange(to: end))
                        } else {
                            Text(start.shortTimeString)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.rhythmTextSecondary)
                }
                
                // Opening action
                if let opening = task.openingAction {
                    Text("→ \(opening)")
                        .font(.caption)
                        .foregroundColor(.rhythmSage)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Status
            if task.status == .inProgress {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.rhythmCoral)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.rhythmCoral)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.rhythmTextMuted)
        }
        .padding(12)
        .background(Color.rhythmCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let currentMonth = calendar.startOfMonth(for: Date())
    
    // Generate months
    let months: [Date] = (-3...3).compactMap { offset in
        calendar.date(byAdding: .month, value: offset, to: currentMonth)
    }
    
    // Sample tasks provider
    let tasksForMonth: (Date) -> [Date: [RhythmTask]] = { month in
        var result: [Date: [RhythmTask]] = [:]
        
        // Add some sample tasks for today
        let today = calendar.startOfDay(for: Date())
        result[today] = [
            RhythmTask(
                title: "Morning standup",
                windowStart: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today),
                priority: .urgent
            ),
            RhythmTask(
                title: "Review PRs",
                windowStart: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today),
                priority: .normal
            )
        ]
        
        // Add tasks for tomorrow
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) {
            result[tomorrow] = [
                RhythmTask(
                    title: "Team meeting",
                    windowStart: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow),
                    priority: .normal
                )
            ]
        }
        
        // Add tasks scattered in the month
        if let day5 = calendar.date(byAdding: .day, value: 5, to: today) {
            result[calendar.startOfDay(for: day5)] = [
                RhythmTask(title: "Project deadline", priority: .urgent),
                RhythmTask(title: "Send report", priority: .normal),
                RhythmTask(title: "Follow up", priority: .low),
                RhythmTask(title: "Backup", priority: .low)
            ]
        }
        
        return result
    }
    
    return MonthOverviewView(
        months: months,
        tasksForMonth: tasksForMonth
    )
}
