//
//  AddTaskSheet.swift
//  Rhythm
//
//  Form for adding a new task
//

import SwiftUI

struct AddTaskSheet: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Form state
    @State private var title: String = ""
    @State private var estimatedMinutes: Int = 30
    @State private var dueAt: Date = Date().addingTimeInterval(86400) // Tomorrow
    @State private var priority: TaskPriority = .normal
    @State private var openingAction: String = ""
    @State private var notes: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, openingAction, notes
    }
    
    private let estimateOptions = [15, 30, 45, 60, 90, 120]
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        titleSection
                        
                        // Estimate time
                        estimateSection
                        
                        // Due at
                        dueAtSection
                        
                        // Priority
                        prioritySection
                        
                        // First step (optional)
                        firstStepSection
                        
                        // Notes (optional)
                        notesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                
                // Bottom action area
                VStack {
                    Spacer()
                    bottomActions
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.rhythmTextSecondary)
                }
            }
            .onAppear {
                focusedField = .title
            }
        }
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Title", icon: "textformat", required: true)
            
            TextField("What do you want to do?", text: $title)
                .font(.body)
                .padding()
                .background(Color.rhythmCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($focusedField, equals: .title)
        }
    }
    
    // MARK: - Estimate Section
    
    private var estimateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Estimate Time", icon: "hourglass", required: true)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(estimateOptions, id: \.self) { mins in
                        estimateButton(mins)
                    }
                }
            }
        }
    }
    
    private func estimateButton(_ mins: Int) -> some View {
        Button {
            estimatedMinutes = mins
        } label: {
            Text(formatMinutes(mins))
                .font(.subheadline)
                .fontWeight(estimatedMinutes == mins ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    estimatedMinutes == mins
                        ? Color.rhythmCoral.opacity(0.15)
                        : Color.rhythmChipBackground
                )
                .foregroundColor(
                    estimatedMinutes == mins
                        ? .rhythmCoral
                        : .rhythmTextPrimary
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(estimatedMinutes == mins ? Color.rhythmCoral : Color.clear, lineWidth: 1.5)
                )
        }
    }
    
    private func formatMinutes(_ mins: Int) -> String {
        if mins < 60 {
            return "\(mins) min"
        } else {
            let hours = mins / 60
            let remaining = mins % 60
            if remaining == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remaining) min"
            }
        }
    }
    
    // MARK: - Due At Section
    
    private var dueAtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Due At", icon: "calendar", required: true)
            
            DatePicker(
                "",
                selection: $dueAt,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.rhythmCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Priority Section
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Priority", icon: "flag", required: true)
            
            HStack(spacing: 10) {
                ForEach(TaskPriority.allCases, id: \.self) { p in
                    priorityButton(p)
                }
            }
        }
    }
    
    private func priorityButton(_ p: TaskPriority) -> some View {
        Button {
            priority = p
        } label: {
            Text(p.displayName)
                .font(.subheadline)
                .fontWeight(priority == p ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    priority == p
                        ? p.color.opacity(0.15)
                        : Color.rhythmChipBackground
                )
                .foregroundColor(
                    priority == p
                        ? p.color
                        : .rhythmTextPrimary
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(priority == p ? p.color : Color.clear, lineWidth: 1.5)
                )
        }
    }
    
    // MARK: - First Step Section
    
    private var firstStepSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("First Step", icon: "arrow.right.circle", required: false)
            
            TextField("What's the first thing you'll do?", text: $openingAction)
                .font(.body)
                .padding()
                .background(Color.rhythmCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($focusedField, equals: .openingAction)
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Notes", icon: "note.text", required: false)
            
            TextField("Any additional details...", text: $notes, axis: .vertical)
                .font(.body)
                .lineLimit(3...6)
                .padding()
                .background(Color.rhythmCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($focusedField, equals: .notes)
        }
    }
    
    // MARK: - Section Label
    
    private func sectionLabel(_ text: String, icon: String, required: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.rhythmCoral)
                .font(.subheadline)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.rhythmTextPrimary)
            
            if !required {
                Text("(optional)")
                    .font(.caption)
                    .foregroundColor(.rhythmTextMuted)
            }
        }
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        VStack(spacing: 12) {
            GentleButton(
                title: "Add Task",
                icon: "plus",
                isDisabled: !canSave
            ) {
                saveTask()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.rhythmBackground(for: colorScheme)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
    
    // MARK: - Actions
    
    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        viewModel.addTask(
            title: trimmedTitle,
            estimatedMinutes: estimatedMinutes,
            deadline: dueAt,
            priority: priority,
            openingAction: openingAction.isEmpty ? nil : openingAction,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddTaskSheet(
        viewModel: TasksViewModel(
            eventLogService: EventLogService(),
            notificationScheduler: NotificationScheduler()
        )
    )
}
