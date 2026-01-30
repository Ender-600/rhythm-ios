//
//  PlanView.swift
//  Rhythm
//
//  Plan view with three modes:
//  - Today: 24-hour vertical timeline
//  - 3 Days: Horizontal scrolling columns
//  - Month: Calendar grid overview
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
                
                VStack(spacing: 0) {
                    // Header with greeting and period selector
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection
                        periodSelector
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Plan content (takes remaining space)
                    if viewModel.isLoading {
                        LoadingView(message: "Loading your rhythm...")
                            .frame(maxHeight: .infinity)
                    } else {
                        planContent
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
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Copy.greeting)
                .font(.title2)
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
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectPeriod(period)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: period.icon)
                            .font(.caption)
                        
                        Text(period.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                    }
                    .foregroundColor(
                        viewModel.selectedPeriod == period
                            ? .rhythmCoral
                            : .rhythmTextSecondary
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        viewModel.selectedPeriod == period
                            ? Color.rhythmCoral.opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(Color.rhythmCard(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Plan Content
    
    @ViewBuilder
    private var planContent: some View {
        switch viewModel.selectedPeriod {
        case .today:
            // 24-hour vertical timeline
            TodayTimelineView(
                tasks: viewModel.todayTasks,
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
            .refreshable {
                await viewModel.refresh()
            }
            
        case .nearFuture:
            // 3-column horizontal scrolling view
            ThreeDayView(
                dateRange: viewModel.dateRangeForThreeDayView(),
                tasksProvider: { date in
                    viewModel.tasksForDate(date)
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
            
        case .monthOverview:
            // Month calendar grid
            MonthOverviewView(
                months: viewModel.monthsForMonthView(),
                tasksForMonth: { month in
                    viewModel.tasksForMonth(month)
                },
                onDayTap: { date in
                    // Could switch to today view for that date
                },
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

