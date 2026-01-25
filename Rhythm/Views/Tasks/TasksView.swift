//
//  TasksView.swift
//  Rhythm
//
//  Board + List view toggle for all tasks
//

import SwiftUI

struct TasksView: View {
    @Bindable var viewModel: TasksViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTask: RhythmTask?
    @State private var showingTaskDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Toolbar
                    toolbar
                    
                    // Content
                    if viewModel.isLoading {
                        LoadingView(message: "Loading tasks...")
                    } else if viewModel.tasks.isEmpty {
                        emptyState
                    } else {
                        taskContent
                    }
                }
            }
            .navigationTitle(Copy.Tasks.title)
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showingSnoozeSheet) {
                if let task = viewModel.selectedTask {
                    SnoozeSheet(
                        task: task,
                        onSnooze: { option in
                            Task {
                                await viewModel.snoozeTask(task, option: option)
                            }
                            viewModel.showingSnoozeSheet = false
                        },
                        onDismiss: {
                            viewModel.showingSnoozeSheet = false
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $viewModel.showingCompletionSheet) {
                if let task = viewModel.selectedTask {
                    CompletionSheet(
                        task: task,
                        onConfirm: { minutes, notes in
                            viewModel.confirmCompletion(actualMinutes: minutes, notes: notes)
                        },
                        onDismiss: {
                            viewModel.showingCompletionSheet = false
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddTaskSheet(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.rhythmCoral)
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack {
            // View mode toggle
            HStack(spacing: 0) {
                ForEach(TasksViewModel.ViewMode.allCases, id: \.self) { mode in
                    Button {
                        viewModel.viewMode = mode
                    } label: {
                        Image(systemName: mode.icon)
                            .font(.subheadline)
                            .foregroundColor(
                                viewModel.viewMode == mode
                                    ? .rhythmCoral
                                    : .rhythmTextSecondary
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.viewMode == mode
                                    ? Color.rhythmCoral.opacity(0.15)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(4)
            .background(Color.rhythmCard(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Spacer()
            
            // Task counts
            HStack(spacing: 12) {
                countBadge(viewModel.taskCounts.notStarted, color: .rhythmTextSecondary)
                countBadge(viewModel.taskCounts.inProgress, color: .rhythmCoral)
                countBadge(viewModel.taskCounts.done, color: .rhythmSuccess)
            }
            
            Spacer()
            
            // Sort menu
            Menu {
                ForEach(TasksViewModel.SortOption.allCases, id: \.self) { option in
                    Button {
                        Task {
                            await viewModel.setSortOption(option)
                        }
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(.rhythmTextSecondary)
                    .padding(8)
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func countBadge(_ count: Int, color: Color) -> some View {
        Text("\(count)")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
    
    // MARK: - Task Content
    
    @ViewBuilder
    private var taskContent: some View {
        switch viewModel.viewMode {
        case .board:
            TaskBoardView(
                notStartedTasks: viewModel.notStartedTasks,
                inProgressTasks: viewModel.inProgressTasks,
                doneTasks: viewModel.doneTasks,
                onTaskTap: { task in
                    selectedTask = task
                    showingTaskDetail = true
                },
                onTaskStart: { task in
                    viewModel.startTask(task)
                },
                onTaskComplete: { task in
                    viewModel.showCompletionFlow(for: task)
                },
                onTaskSnooze: { task in
                    viewModel.selectedTask = task
                    viewModel.showingSnoozeSheet = true
                }
            )
            
        case .list:
            ScrollView {
                TaskListView(
                    tasks: viewModel.tasks,
                    onTaskTap: { task in
                        selectedTask = task
                        showingTaskDetail = true
                    },
                    onTaskStart: { task in
                        viewModel.startTask(task)
                    },
                    onTaskComplete: { task in
                        viewModel.showCompletionFlow(for: task)
                    },
                    onTaskSnooze: { task in
                        viewModel.selectedTask = task
                        viewModel.showingSnoozeSheet = true
                    },
                    onTaskDelete: { task in
                        viewModel.deleteTask(task)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "checkmark.circle",
            title: Copy.Tasks.allDone,
            message: "Tap + to add a new task"
        )
    }
}

// MARK: - Completion Sheet

struct CompletionSheet: View {
    let task: RhythmTask
    var onConfirm: (Int?, String?) -> Void
    var onDismiss: () -> Void
    
    @State private var actualMinutes: Int?
    @State private var notes: String = ""
    @State private var selectedFeeling: String?
    
    private let feelings = [
        (Copy.Completion.feelingGreat, "😊"),
        (Copy.Completion.feelingOkay, "😐"),
        (Copy.Completion.feelingDrained, "😮‍💨")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(Copy.Completion.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(Copy.Completion.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.rhythmTextSecondary)
                }
                .padding(.top)
                
                // Task title
                Text(task.title)
                    .font(.body)
                    .foregroundColor(.rhythmTextPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.rhythmSuccess.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                
                // Duration input
                VStack(alignment: .leading, spacing: 8) {
                    Text(Copy.Completion.durationQuestion)
                        .font(.subheadline)
                        .foregroundColor(.rhythmTextSecondary)
                    
                    HStack {
                        ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                            Button {
                                actualMinutes = mins
                            } label: {
                                Text("\(mins)m")
                                    .font(.subheadline)
                                    .fontWeight(actualMinutes == mins ? .semibold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        actualMinutes == mins
                                            ? Color.rhythmCoral.opacity(0.15)
                                            : Color.rhythmChipBackground
                                    )
                                    .foregroundColor(
                                        actualMinutes == mins
                                            ? .rhythmCoral
                                            : .rhythmTextPrimary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Feeling selector
                VStack(alignment: .leading, spacing: 8) {
                    Text(Copy.Completion.feelingQuestion)
                        .font(.subheadline)
                        .foregroundColor(.rhythmTextSecondary)
                    
                    HStack(spacing: 12) {
                        ForEach(feelings, id: \.0) { feeling, emoji in
                            Button {
                                selectedFeeling = feeling
                            } label: {
                                VStack(spacing: 4) {
                                    Text(emoji)
                                        .font(.title2)
                                    Text(feeling)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    selectedFeeling == feeling
                                        ? Color.rhythmCoral.opacity(0.15)
                                        : Color.rhythmChipBackground
                                )
                                .foregroundColor(
                                    selectedFeeling == feeling
                                        ? .rhythmCoral
                                        : .rhythmTextPrimary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    GentleButton(title: Copy.Completion.saveButton) {
                        onConfirm(actualMinutes, notes.isEmpty ? nil : notes)
                    }
                    
                    GentleTextButton(title: Copy.Completion.skipButton) {
                        onConfirm(nil, nil)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TasksView(
        viewModel: TasksViewModel(
            eventLogService: EventLogService(),
            notificationScheduler: NotificationScheduler()
        )
    )
}

