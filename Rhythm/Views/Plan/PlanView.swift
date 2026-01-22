//
//  PlanView.swift
//  Rhythm
//
//  Day/Week/Month plan view
//  Shows a "plan sketch" - flexible, not rigid
//

import SwiftUI

struct PlanView: View {
    @Bindable var viewModel: PlanViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTask: RhythmTask?
    @State private var showingSnoozeSheet = false
    @State private var showingTaskDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Greeting and summary
                        headerSection
                        
                        // Period selector
                        periodSelector
                        
                        // Plan content
                        if viewModel.isLoading {
                            LoadingView(message: "Loading your rhythm...")
                        } else {
                            planContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.refresh()
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
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Copy.greeting)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.rhythmTextPrimary)
            
            Text(viewModel.summaryText)
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(PlanViewModel.PlanPeriod.allCases, id: \.self) { period in
                Button {
                    Task {
                        await viewModel.selectPeriod(period)
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(
                            viewModel.selectedPeriod == period
                                ? .rhythmCoral
                                : .rhythmTextSecondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedPeriod == period
                                ? Color.rhythmCoral.opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(Color.rhythmCard(for: colorScheme))
        .clipShape(Capsule())
    }
    
    // MARK: - Plan Content
    
    @ViewBuilder
    private var planContent: some View {
        switch viewModel.selectedPeriod {
        case .day:
            PlanSketchView(
                tasks: viewModel.tasks,
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
            
        case .week, .month:
            PrioritySectionsView(
                urgentTasks: viewModel.urgentTasks,
                normalTasks: viewModel.normalTasks,
                lowTasks: viewModel.lowTasks,
                onTaskTap: { task in
                    selectedTask = task
                    showingTaskDetail = true
                }
            )
        }
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
                        .font(.title3)
                        .fontWeight(.semibold)
                    
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
                    .clipShape(RoundedRectangle(cornerRadius: 10))
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

