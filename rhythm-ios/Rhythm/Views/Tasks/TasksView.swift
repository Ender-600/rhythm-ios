//
//  TasksView.swift
//  Rhythm
//
//  Prioritized vertical task list
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
    
    // MARK: - Task Content
    
    @ViewBuilder
    private var taskContent: some View {
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
                },
                onMove: { source, destination in
                    viewModel.moveTasks(from: source, to: destination)
                }
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
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
