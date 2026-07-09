//
//  PlanView.swift
//  Rhythm
//
//  Calendar that zooms from month, to week, to a minute-level day timeline.
//

import SwiftUI

struct PlanView: View {
    @Bindable var viewModel: PlanViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTask: RhythmTask?
    @State private var selectedPlanWindow: PlanTimeSelection?
    @State private var showingSnoozeSheet = false
    @State private var showingTaskDetail = false
    @GestureState private var liveMagnification: CGFloat = 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header and current calendar precision
                    VStack(alignment: .leading, spacing: 14) {
                        headerSection
                        zoomControl
                    }
                    .padding(.horizontal, QuietSwiss.screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Plan content (takes remaining space)
                    if viewModel.isLoading {
                        LoadingView(message: "Loading your rhythm...")
                            .frame(maxHeight: .infinity)
                    } else {
                        planContent
                            .id(viewModel.zoomLevel)
                            .scaleEffect(contentScale)
                            .opacity(contentOpacity)
                            .simultaneousGesture(zoomGesture)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSnoozeSheet) {
                if let task = selectedTask {
                    SnoozeSheet(
                        task: task,
                        onSnooze: { option in
                            Task {
                                await viewModel.snoozeTask(task, option: option)
                            }
                            showingSnoozeSheet = false
                        },
                        onDismiss: {
                            showingSnoozeSheet = false
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
            .sheet(item: $selectedPlanWindow) { selection in
                PlanCreationSheet(selection: selection, viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Copy.greeting.uppercased())
                    .swissSectionLabel(color: .rhythmSignal)

                Text(viewModel.summaryText)
                    .font(.system(size: 29, weight: .bold))
                    .tracking(-0.8)
                    .foregroundColor(.rhythmTextPrimary)
            }

            Spacer()

            if !Calendar.current.isDateInToday(viewModel.focusedDate) {
                Button("Today") {
                    withAnimation(.snappy) {
                        viewModel.resetToToday()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.rhythmSignal)
            }
        }
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            SwissRule(strong: true)
        }
    }
    
    // MARK: - Zoom Control

    private var zoomControl: some View {
        HStack(spacing: 12) {
            zoomButton(systemName: "minus.magnifyingglass", enabled: viewModel.canZoomOut) {
                changeZoom { viewModel.zoomOut() }
            }

            VStack(spacing: 2) {
                Label(viewModel.zoomLevel.title, systemImage: viewModel.zoomLevel.icon)
                    .font(.caption.weight(.black))
                    .textCase(.uppercase)
                    .tracking(1)
                    .foregroundStyle(Color.rhythmSignal)

                Text(viewModel.focusedRangeTitle)
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.rhythmTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            zoomButton(systemName: "plus.magnifyingglass", enabled: viewModel.canZoomIn) {
                changeZoom { viewModel.zoomIn() }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .swissSurface()
    }

    private func zoomButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 36, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.rhythmTextPrimary : Color.rhythmTextMuted.opacity(0.35))
        .disabled(!enabled)
    }
    
    // MARK: - Plan Content
    
    @ViewBuilder
    private var planContent: some View {
        switch viewModel.zoomLevel {
        case .day:
            TodayTimelineView(
                date: viewModel.focusedDate,
                tasks: viewModel.focusedDayTasks,
                onTaskTap: { task in
                    selectedTask = task
                    showingTaskDetail = true
                },
                onSnooze: { task in
                    selectedTask = task
                    showingSnoozeSheet = true
                },
                onStart: { task in
                    viewModel.startTask(task)
                },
                onCreateSelection: { selection in
                    selectedPlanWindow = selection
                }
            )
            .refreshable {
                await viewModel.refresh()
            }
            
        case .week:
            WeekAgendaView(
                dates: viewModel.weekDates(containing: viewModel.focusedDate),
                focusedDate: viewModel.focusedDate,
                tasksProvider: { date in
                    viewModel.tasksForDate(date)
                },
                onDayTap: { date in
                    changeZoom {
                        viewModel.focus(on: date, zoomTo: .day)
                    }
                },
                onTaskTap: { task in
                    selectedTask = task
                    showingTaskDetail = true
                },
                onSnooze: { task in
                    selectedTask = task
                    showingSnoozeSheet = true
                },
                onStart: { task in
                    viewModel.startTask(task)
                }
            )
            
        case .month:
            MonthOverviewView(
                months: viewModel.monthsForMonthView(),
                focusedDate: viewModel.focusedDate,
                tasksForMonth: { month in
                    viewModel.tasksForMonth(month)
                },
                onDayTap: { date in
                    changeZoom {
                        viewModel.focus(on: date, zoomTo: .week)
                    }
                }
            )
        }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0.01)
            .updating($liveMagnification) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                if value.magnification > 1.16, viewModel.canZoomIn {
                    changeZoom { viewModel.zoomIn() }
                } else if value.magnification < 0.86, viewModel.canZoomOut {
                    changeZoom { viewModel.zoomOut() }
                }
            }
    }

    private var contentScale: CGFloat {
        let delta = (liveMagnification - 1) * 0.08
        return min(max(1 + delta, 0.96), 1.04)
    }

    private var contentOpacity: Double {
        min(max(1 - abs(liveMagnification - 1) * 0.12, 0.88), 1)
    }

    private func changeZoom(_ update: () -> Void) {
        withAnimation(.snappy(duration: 0.28)) {
            update()
        }
    }
}

// MARK: - Plan Creation Sheet

private struct PlanCreationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let selection: PlanTimeSelection
    let viewModel: PlanViewModel

    @State private var title = ""
    @State private var start: Date
    @State private var durationMinutes: Int
    @State private var priority: TaskPriority = .normal
    @State private var openingAction = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(selection: PlanTimeSelection, viewModel: PlanViewModel) {
        self.selection = selection
        self.viewModel = viewModel
        _start = State(initialValue: selection.start)
        _durationMinutes = State(initialValue: selection.durationMinutes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section {
                        TextField("Title", text: $title)
                            .textInputAutocapitalization(.sentences)

                        DatePicker(
                            "Starts",
                            selection: $start,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        Stepper(value: $durationMinutes, in: 15...480, step: 15) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text(formatDuration(durationMinutes))
                                    .foregroundColor(.rhythmTextSecondary)
                            }
                        }
                    }

                    Section {
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section {
                        TextField("First step", text: $openingAction, axis: .vertical)
                            .lineLimit(1...2)

                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(2...5)
                    }

                    if let errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(Color.rhythmError)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    private var end: Date {
        start.adding(minutes: durationMinutes)
    }

    private func save() async {
        guard canSave else { return }

        isSaving = true
        errorMessage = nil

        do {
            try await viewModel.createPlan(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                start: start,
                end: end,
                priority: priority,
                openingAction: openingAction.trimmedOrNil,
                notes: notes.trimmedOrNil
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remaining = minutes % 60
        if remaining == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remaining)m"
    }
}

private extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Snooze Sheet

struct SnoozeSheet: View {
    let task: RhythmTask
    var onSnooze: (SnoozeOption) -> Void
    var onDismiss: () -> Void
    
    @State private var selectedOption: SnoozeOption?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(Copy.Snooze.title)
                        .font(.system(size: 26, weight: .bold))
                        .tracking(-0.5)
                    
                    Text(Copy.Snooze.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.rhythmTextSecondary)
                }
                .padding(.top)
                
                // Task preview
                Text(task.title)
                    .font(.body)
                    .foregroundColor(.rhythmTextPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.rhythmChipBackground)
                    .swissSurface()
                    .padding(.horizontal)
                
                // Snooze options
                VStack(spacing: 10) {
                    ForEach([SnoozeOption.tenMinutes, .thirtyMinutes, .oneHour], id: \.self) { option in
                        SnoozeButton(
                            option: option,
                            isSelected: selectedOption == option
                        ) {
                            selectedOption = option
                        }
                    }
                    
                    HStack(spacing: 10) {
                        SnoozeButton(
                            option: .tonight,
                            isSelected: selectedOption == .tonight
                        ) {
                            selectedOption = .tonight
                        }
                        
                        SnoozeButton(
                            option: .tomorrow,
                            isSelected: selectedOption == .tomorrow
                        ) {
                            selectedOption = .tomorrow
                        }
                    }
                    
                    SnoozeButton(
                        option: .custom(60),
                        isSelected: {
                            if case .custom = selectedOption {
                                return true
                            }
                            return false
                        }()
                    ) {
                        selectedOption = .custom(60)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Confirm button
                GentleButton(
                    title: Copy.Snooze.confirm,
                    isDisabled: selectedOption == nil
                ) {
                    if let option = selectedOption {
                        onSnooze(option)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.Snooze.cancel) {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PlanView(
        viewModel: PlanViewModel(
            notificationScheduler: NotificationScheduler(),
            eventLogService: EventLogService()
        )
    )
}
