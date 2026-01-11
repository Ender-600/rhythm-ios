//
//  TimeWindowPicker.swift
//  Rhythm
//
//  Options-first time window selection
//  Always shows 2-3 suggestions + custom option
//

import SwiftUI

struct TimeWindowPicker: View {
    let windows: [CandidateWindow]
    @Binding var selectedId: String?
    var onCustomTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.QuickAdd.timeHeader)
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
            
            VStack(spacing: 8) {
                ForEach(windows) { window in
                    TimeWindowOption(
                        window: window,
                        isSelected: selectedId == window.id
                    ) {
                        if window.isCustom {
                            onCustomTap()
                        } else {
                            selectedId = window.id
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Time Window Option

struct TimeWindowOption: View {
    let window: CandidateWindow
    var isSelected: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .rhythmCoral : .rhythmTextMuted)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(window.label)
                            .font(.body)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(.rhythmTextPrimary)
                        
                        if window.isRecommended && !isSelected {
                            Text("Suggested")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.rhythmCoral.opacity(0.15))
                                .foregroundColor(.rhythmCoral)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if !window.isCustom, let start = window.startTime {
                        Text(formatTimeRange(start: start, end: window.endTime))
                            .font(.caption)
                            .foregroundColor(.rhythmTextSecondary)
                    } else {
                        Text(window.gentleDescription)
                            .font(.caption)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                }
                
                Spacer()
                
                if window.isCustom {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.rhythmTextMuted)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.rhythmCoral.opacity(0.1) : Color.rhythmCardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.rhythmCoral : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatTimeRange(start: Date, end: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        var result = formatter.string(from: start)
        if let end = end {
            result += " - \(formatter.string(from: end))"
        }
        
        // Add day context if not today
        let calendar = Calendar.current
        if !calendar.isDateInToday(start) {
            let dayFormatter = DateFormatter()
            if calendar.isDateInTomorrow(start) {
                dayFormatter.dateFormat = "'Tomorrow,' "
            } else {
                dayFormatter.dateFormat = "EEE, "
            }
            result = dayFormatter.string(from: start) + result
        }
        
        return result
    }
}

// MARK: - Custom Time Picker Sheet

struct CustomTimePickerSheet: View {
    @Binding var isPresented: Bool
    @Binding var startTime: Date?
    @Binding var endTime: Date?
    var onConfirm: () -> Void
    
    @State private var selectedDate = Date()
    @State private var selectedStartTime = Date()
    @State private var duration: Int = 60 // minutes
    
    private let durationOptions = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    
                    DatePicker(
                        "Start time",
                        selection: $selectedStartTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section("Duration") {
                    Picker("Duration", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { mins in
                            Text(formatDuration(mins)).tag(mins)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    HStack {
                        Text("Window")
                        Spacer()
                        Text(computedWindowDescription)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                }
            }
            .navigationTitle("Pick a time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applySelection()
                        onConfirm()
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var computedWindowDescription: String {
        let start = combinedStartTime
        let end = start.adding(minutes: duration)
        return start.timeRange(to: end)
    }
    
    private var combinedStartTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedStartTime)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? Date()
    }
    
    private func applySelection() {
        let start = combinedStartTime
        startTime = start
        endTime = start.adding(minutes: duration)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    TimeWindowPicker(
        windows: [
            CandidateWindow(
                id: "1",
                label: "This evening",
                gentleDescription: "Wind-down time",
                startTime: Date().adding(hours: 3),
                endTime: Date().adding(hours: 5),
                isCustom: false,
                isRecommended: true
            ),
            CandidateWindow(
                id: "2",
                label: "Tomorrow morning",
                gentleDescription: "Fresh start",
                startTime: Date().adding(hours: 15),
                endTime: Date().adding(hours: 18),
                isCustom: false,
                isRecommended: false
            ),
            .custom
        ],
        selectedId: .constant("1"),
        onCustomTap: {}
    )
    .padding()
}

