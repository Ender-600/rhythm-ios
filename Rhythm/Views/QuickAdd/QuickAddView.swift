//
//  QuickAddView.swift
//  Rhythm
//
//  Primary voice-first task creation interface
//  Voice button at the bottom for easy thumb reach
//

import SwiftUI

struct QuickAddView: View {
    @Bindable var viewModel: QuickAddViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingCustomTimePicker = false
    @State private var typedInput = ""
    @FocusState private var isTyping: Bool
    
    // Equatable proxy for FlowState
    private var flowStateTag: Int {
        switch viewModel.flowState {
        case .idle: return 0
        case .recording: return 1
        case .processing: return 2
        case .reviewingSummary: return 3
        case .reviewingCreate: return 4
        case .reviewingUpdate: return 5
        case .selectingTask: return 6
        case .customizingTime: return 7
        case .saving: return 8
        case .completed: return 9
        case .error: return 10
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.rhythmBackground(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content area
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection
                        
                        // Transcription / Input area
                        inputSection
                        
                        // Schedule info (for create flow)
                        if case .reviewingCreate = viewModel.flowState {
                            scheduleSection
                        }
                        
                        // Multi-intent summary
                        if case .reviewingSummary = viewModel.flowState {
                            intentSummarySection
                        }
                        
                        // Task selection (for update flow)
                        if case .selectingTask = viewModel.flowState {
                            taskSelectionSection
                        }
                        
                        // Update confirmation
                        if case .reviewingUpdate = viewModel.flowState {
                            updateConfirmSection
                        }
                        
                        // Error message
                        if let error = viewModel.voiceError ?? viewModel.saveError {
                            ErrorBanner(message: error) {
                                viewModel.clearErrors()
                            } dismissAction: {
                                viewModel.clearErrors()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120) // Space for voice button
                }
                
                Spacer()
            }
            
            // Bottom action area
            VStack {
                Spacer()
                bottomActionArea
            }
        }
        .sheet(isPresented: $showingCustomTimePicker) {
            CustomTimePickerSheet(
                isPresented: $showingCustomTimePicker,
                startTime: $viewModel.customWindowStart,
                endTime: $viewModel.customWindowEnd
            ) {
                viewModel.setCustomWindow(
                    start: viewModel.customWindowStart ?? Date(),
                    end: viewModel.customWindowEnd ?? Date().adding(hours: 1)
                )
            }
        }
        .onChange(of: flowStateTag) { _, _ in
            if case .completed = viewModel.flowState {
                // Could show success animation here
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch viewModel.flowState {
            case .idle, .error:
                Text(Copy.QuickAdd.prompt)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextPrimary)
                
            case .recording:
                Text(Copy.QuickAdd.voiceRecording)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmRecording)
                
            case .processing:
                HStack(spacing: 8) {
                    ProgressView()
                    Text(Copy.QuickAdd.voiceProcessing)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.rhythmTextPrimary)
                }
                
            case .reviewingSummary:
                Text("I understood \(viewModel.totalIntentCount) things")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextPrimary)
                
            case .reviewingCreate, .customizingTime, .saving:
                if viewModel.hasMultipleIntents {
                    Text("Task \(viewModel.currentIntentProgress.current) of \(viewModel.currentIntentProgress.total)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.rhythmTextPrimary)
                } else {
                    Text("Looking good!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.rhythmTextPrimary)
                }
                
            case .reviewingUpdate:
                Text(viewModel.updateAction?.displayName ?? "Update")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextPrimary)
                
            case .selectingTask:
                Text("Which task?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextPrimary)
                
            case .completed:
                Text(Copy.QuickAdd.successTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmSuccess)
            }
        }
    }
    
    // MARK: - Input Section
    
    @ViewBuilder
    private var inputSection: some View {
        switch viewModel.flowState {
        case .idle, .error:
            // Show text input option
            VStack(spacing: 16) {
                TextField(Copy.QuickAdd.typingPlaceholder, text: $typedInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($isTyping)
                    .onSubmit {
                        if !typedInput.isEmpty {
                            Task {
                                await viewModel.processTypedInput(typedInput)
                            }
                        }
                    }
                
                if !typedInput.isEmpty {
                    GentleTextButton(title: "Process", icon: "arrow.right") {
                        Task {
                            await viewModel.processTypedInput(typedInput)
                        }
                    }
                }
            }
            
        case .recording:
            // Show live transcription
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.speechService.partialTranscript.isEmpty ? "..." : viewModel.speechService.partialTranscript)
                    .font(.body)
                    .foregroundColor(.rhythmTextPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.rhythmRecording.opacity(0.5), lineWidth: 2)
                    )
            }
            
        case .processing:
            Text(viewModel.transcript)
                .font(.body)
                .foregroundColor(.rhythmTextPrimary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.rhythmCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
        case .reviewingSummary:
            // Show original transcript
            Text(viewModel.transcript)
                .font(.body)
                .foregroundColor(.rhythmTextSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.rhythmCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
        case .reviewingCreate, .customizingTime, .saving:
            // Editable title
            VStack(alignment: .leading, spacing: 8) {
                Text("Task")
                    .font(.caption)
                    .foregroundColor(.rhythmTextSecondary)
                
                TextField("Task title", text: $viewModel.editedTitle, axis: .vertical)
                    .font(.body)
                    .padding()
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
        case .reviewingUpdate, .selectingTask:
            // Show update description
            if let description = viewModel.updateActionDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(.rhythmTextPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
        case .completed:
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.rhythmSuccess)
                
                if let message = viewModel.completionMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.rhythmTextSecondary)
                } else {
                    Text(Copy.QuickAdd.successMessage)
                        .font(.subheadline)
                        .foregroundColor(.rhythmTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Schedule Section
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let timeDesc = viewModel.selectedTimeDescription {
                VStack(alignment: .leading, spacing: 4) {
                    Text("When")
                        .font(.caption)
                        .foregroundColor(.rhythmTextSecondary)
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.rhythmCoral)
                        Text(timeDesc)
                            .foregroundColor(.rhythmTextPrimary)
                        Spacer()
                        Button {
                            showingCustomTimePicker = true
                        } label: {
                            Text("Change")
                                .font(.caption)
                                .foregroundColor(.rhythmCoral)
                        }
                    }
                    .padding()
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Priority
            VStack(alignment: .leading, spacing: 4) {
                Text("Priority")
                    .font(.caption)
                    .foregroundColor(.rhythmTextSecondary)
                
                HStack(spacing: 8) {
                    ForEach([TaskPriority.low, .normal, .urgent], id: \.self) { priority in
                        PriorityChip(priority: priority, isCompact: true)
                            .opacity(viewModel.suggestedPriority == priority ? 1 : 0.5)
                    }
                }
            }
        }
    }
    
    // MARK: - Intent Summary Section
    
    private var intentSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(viewModel.intentSummary.enumerated()), id: \.offset) { index, item in
                HStack {
                    Image(systemName: item.type == "Create" ? "plus.circle.fill" : "arrow.triangle.2.circlepath")
                        .foregroundColor(item.type == "Create" ? .rhythmSage : .rhythmAmber)
                    
                    VStack(alignment: .leading) {
                        Text(item.type)
                            .font(.caption)
                            .foregroundColor(.rhythmTextSecondary)
                        Text(item.description)
                            .font(.body)
                            .foregroundColor(.rhythmTextPrimary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.rhythmCard(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Task Selection Section
    
    private var taskSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Multiple tasks match. Select one:")
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
            
            ForEach(viewModel.matchedTasks, id: \.id) { task in
                Button {
                    viewModel.selectTaskForUpdate(task)
                } label: {
                    HStack {
                        Text(task.title)
                            .foregroundColor(.rhythmTextPrimary)
                        Spacer()
                        if let window = task.windowDescription {
                            Text(window)
                                .font(.caption)
                                .foregroundColor(.rhythmTextSecondary)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundColor(.rhythmTextMuted)
                    }
                    .padding()
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Update Confirm Section
    
    private var updateConfirmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let task = viewModel.selectedTaskForUpdate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task")
                        .font(.caption)
                        .foregroundColor(.rhythmTextSecondary)
                    
                    Text(task.title)
                        .font(.body)
                        .foregroundColor(.rhythmTextPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.rhythmCard(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if let action = viewModel.updateAction {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.rhythmAmber)
                        Text(action.confirmationMessage)
                            .foregroundColor(.rhythmTextPrimary)
                    }
                    .padding()
                    .background(Color.rhythmAmber.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Bottom Action Area
    
    private var bottomActionArea: some View {
        VStack(spacing: 16) {
            switch viewModel.flowState {
            case .idle, .error, .recording:
                VoiceButtonContainer(viewModel: viewModel)
                    .padding(.bottom, 8)
                
            case .processing:
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.bottom, 24)
                
            case .reviewingSummary:
                HStack(spacing: 12) {
                    GentleButton(
                        title: Copy.QuickAdd.cancelButton,
                        style: .subtle
                    ) {
                        viewModel.reset()
                        typedInput = ""
                    }
                    
                    GentleButton(
                        title: "Confirm All",
                        icon: "checkmark"
                    ) {
                        Task {
                            await viewModel.confirmAllIntents()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
            case .reviewingCreate, .customizingTime:
                HStack(spacing: 12) {
                    GentleButton(
                        title: Copy.QuickAdd.cancelButton,
                        style: .subtle
                    ) {
                        viewModel.reset()
                        typedInput = ""
                    }
                    
                    GentleButton(
                        title: viewModel.hasMoreIntents ? "Next" : Copy.QuickAdd.createButton,
                        icon: viewModel.hasMoreIntents ? "arrow.right" : "plus",
                        isDisabled: !viewModel.canCreateTask
                    ) {
                        Task {
                            await viewModel.createTask()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
            case .reviewingUpdate:
                HStack(spacing: 12) {
                    GentleButton(
                        title: Copy.QuickAdd.cancelButton,
                        style: .subtle
                    ) {
                        viewModel.reset()
                        typedInput = ""
                    }
                    
                    GentleButton(
                        title: viewModel.hasMoreIntents ? "Next" : "Confirm",
                        icon: viewModel.hasMoreIntents ? "arrow.right" : "checkmark",
                        isDisabled: !viewModel.canExecuteUpdate
                    ) {
                        Task {
                            await viewModel.executeUpdate()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
            case .selectingTask:
                GentleButton(
                    title: Copy.QuickAdd.cancelButton,
                    style: .subtle
                ) {
                    viewModel.reset()
                    typedInput = ""
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
            case .saving:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Processing...")
                        .foregroundColor(.rhythmTextSecondary)
                }
                .padding(.bottom, 24)
                
            case .completed:
                GentleButton(
                    title: Copy.QuickAdd.addAnother,
                    icon: "plus"
                ) {
                    viewModel.startNew()
                    typedInput = ""
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.rhythmBackground(for: colorScheme).opacity(0),
                    Color.rhythmBackground(for: colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Preview

#Preview {
    QuickAddView(
        viewModel: QuickAddViewModel(
            speechService: SpeechService(),
            eventLogService: EventLogService(),
            notificationScheduler: NotificationScheduler()
        )
    )
}

