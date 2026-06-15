//
//  QuickAddViewModel.swift
//  Rhythm
//
//  ViewModel for the voice-first Quick Add flow
//  Orchestrates speech capture, LLM parsing, and task creation/updates
//

import Foundation
import SwiftData

@Observable
@MainActor
final class QuickAddViewModel {
    // MARK: - Published State
    
    // Flow state
    private(set) var flowState: FlowState = .idle
    
    // Voice input
    var transcript: String = ""
    var isRecording: Bool { speechService.isRecording }
    var recordingDuration: TimeInterval { speechService.recordingDuration }
    var voiceError: String?
    
    // Parsed intents (supports multiple)
    private(set) var intentResult: VoiceIntentResult?
    private(set) var intentConfidence: Double = 0
    
    // All create intents to process
    private(set) var pendingCreateIntents: [CreateTaskIntent] = []
    private(set) var currentCreateIndex: Int = 0
    
    // All update intents to process
    private(set) var pendingUpdateIntents: [UpdateTaskIntent] = []
    private(set) var currentUpdateIndex: Int = 0
    
    // Current create task state (for editing)
    private(set) var extractedTitle: String = ""
    private(set) var suggestedPriority: TaskPriority = .normal
    private(set) var scheduleWindow: ScheduleWindow?
    private(set) var deadline: Date?
    private(set) var note: String?
    var editedTitle: String = ""
    var customWindowStart: Date?
    var customWindowEnd: Date?
    
    // Current update task state
    private(set) var updateAction: TaskAction?
    private(set) var matchedTasks: [RhythmTask] = []
    private(set) var selectedTaskForUpdate: RhythmTask?
    
    // Saving state
    private(set) var isSaving = false
    private(set) var saveError: String?
    private(set) var savedTasks: [RhythmTask] = []
    private(set) var updatedTasks: [RhythmTask] = []
    private(set) var completionMessage: String?
    
    // Legacy support
    var savedTask: RhythmTask? { savedTasks.first }
    var currentIntent: VoiceIntent? {
        if let first = pendingCreateIntents.first {
            return .createTask(first)
        } else if let first = pendingUpdateIntents.first {
            return .updateTask(first)
        }
        return nil
    }
    
    // MARK: - Dependencies
    
    let speechService: SpeechService
    private let llmService: LLMService
    private let eventLogService: EventLogService
    private let notificationScheduler: NotificationScheduler
    private var modelContext: ModelContext?
    
    // MARK: - Types
    
    enum FlowState: Equatable {
        case idle                    // Ready to start
        case recording               // Voice input active
        case processing              // Parsing with LLM
        case reviewingSummary        // User reviewing multiple intents summary
        case reviewingCreate         // User reviewing create task (one at a time)
        case reviewingUpdate         // User reviewing update action
        case selectingTask           // User selecting which task to update
        case customizingTime         // User customizing time
        case saving                  // Creating/updating task
        case completed               // Action completed
        case error(String)           // Something went wrong
        
        var canRecord: Bool {
            switch self {
            case .idle, .error, .completed: return true
            default: return false
            }
        }
        
        var isReviewing: Bool {
            switch self {
            case .reviewingSummary, .reviewingCreate, .reviewingUpdate, .selectingTask, .customizingTime:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        speechService: SpeechService,
        eventLogService: EventLogService,
        notificationScheduler: NotificationScheduler,
        llmService: LLMService? = nil
    ) {
        self.speechService = speechService
        self.llmService = llmService ?? LLMService()
        self.eventLogService = eventLogService
        self.notificationScheduler = notificationScheduler
    }
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Voice Input Actions
    
    /// Start voice recording
    func startRecording() async {
        guard flowState.canRecord else { return }
        
        voiceError = nil
        flowState = .recording
        eventLogService.logVoiceInputStarted()
        
        await speechService.startRecording()
        
        // Watch for errors
        if let error = speechService.error {
            voiceError = error.localizedDescription
            flowState = .error(error.localizedDescription)
        }
    }
    
    /// Stop voice recording and process
    func stopRecording() async {
        speechService.stopRecording()
        
        let duration = speechService.recordingDuration
        transcript = speechService.transcript
        
        eventLogService.logVoiceInputCompleted(
            duration: duration,
            transcriptLength: transcript.count
        )
        
        if transcript.isEmpty {
            flowState = .idle
            return
        }
        
        await processUtterance()
    }
    
    /// Cancel recording without processing
    func cancelRecording() {
        let duration = speechService.recordingDuration
        speechService.cancelRecording()
        
        eventLogService.logVoiceInputCancelled(duration: duration)
        
        flowState = .idle
        transcript = ""
    }
    
    /// Process typed input (alternative to voice)
    func processTypedInput(_ text: String) async {
        transcript = text
        await processUtterance()
    }
    
    // MARK: - Processing
    
    private func processUtterance() async {
        flowState = .processing
        
        // Get existing tasks for context
        let existingTasks = fetchExistingTasks()
        
        // Parse all intents using LLM
        let result = await llmService.parseIntents(from: transcript, existingTasks: existingTasks)
        intentResult = result
        intentConfidence = result.confidence
        
        // Store all intents for processing
        pendingCreateIntents = result.createIntents
        pendingUpdateIntents = result.updateIntents
        currentCreateIndex = 0
        currentUpdateIndex = 0
        
        // Determine flow based on intents
        if !result.hasIntents {
            // Fall back to create task with raw text as title
            let fallbackIntent = CreateTaskIntent(
                title: transcript,
                scheduleWindow: nil,
                deadline: nil,
                priority: .normal,
                note: nil,
                rawUtterance: transcript,
                confidence: 0.3
            )
            pendingCreateIntents = [fallbackIntent]
            loadCreateIntent(at: 0)
            flowState = .reviewingCreate
        } else if result.totalIntentCount == 1 {
            // Single intent - go directly to review
            if let createIntent = result.createIntents.first {
                loadCreateIntent(at: 0)
                flowState = .reviewingCreate
            } else if let updateIntent = result.updateIntents.first {
                await loadUpdateIntent(at: 0, existingTasks: existingTasks)
            }
        } else {
            // Multiple intents - show summary first
            flowState = .reviewingSummary
        }
    }
    
    /// Load a create intent for editing
    private func loadCreateIntent(at index: Int) {
        guard index < pendingCreateIntents.count else { return }
        
        let intent = pendingCreateIntents[index]
        currentCreateIndex = index
        
        extractedTitle = intent.title
        editedTitle = intent.title
        suggestedPriority = intent.priority
        scheduleWindow = intent.scheduleWindow
        deadline = intent.deadline
        note = intent.note
        
        // Set custom window if schedule window has times
        if let window = intent.scheduleWindow {
            customWindowStart = window.start
            customWindowEnd = window.end
        } else {
            customWindowStart = nil
            customWindowEnd = nil
        }
    }
    
    /// Load an update intent for execution
    private func loadUpdateIntent(at index: Int, existingTasks: [RhythmTask]) async {
        guard index < pendingUpdateIntents.count else { return }
        
        let intent = pendingUpdateIntents[index]
        currentUpdateIndex = index
        
        updateAction = intent.action
        
        // Find matching tasks
        matchedTasks = findMatchingTasks(for: intent.targetQuery, in: existingTasks)
        
        if matchedTasks.isEmpty {
            flowState = .error("I couldn't find a task matching '\(intent.targetQuery.rawDescription)'. Could you be more specific?")
        } else if matchedTasks.count == 1 {
            selectedTaskForUpdate = matchedTasks.first
            flowState = .reviewingUpdate
        } else {
            flowState = .selectingTask
        }
    }
    
    // MARK: - Multi-Intent Navigation
    
    /// Start processing intents from summary view
    func startProcessingIntents() async {
        let existingTasks = fetchExistingTasks()
        
        // Start with creates, then updates
        if !pendingCreateIntents.isEmpty {
            loadCreateIntent(at: 0)
            flowState = .reviewingCreate
        } else if !pendingUpdateIntents.isEmpty {
            await loadUpdateIntent(at: 0, existingTasks: existingTasks)
        }
    }
    
    /// Confirm all intents and execute them
    func confirmAllIntents() async {
        flowState = .saving
        isSaving = true
        
        let existingTasks = fetchExistingTasks()
        
        // Execute all creates
        for intent in pendingCreateIntents {
            loadCreateIntent(at: pendingCreateIntents.firstIndex(where: { $0.title == intent.title }) ?? 0)
            await createTaskFromCurrentState()
        }
        
        // Execute all updates
        for (index, intent) in pendingUpdateIntents.enumerated() {
            await loadUpdateIntent(at: index, existingTasks: existingTasks)
            if selectedTaskForUpdate != nil {
                await executeUpdateFromCurrentState()
            }
        }
        
        // Build completion message
        var messages: [String] = []
        if !savedTasks.isEmpty {
            messages.append("Created \(savedTasks.count) task\(savedTasks.count > 1 ? "s" : "")")
        }
        if !updatedTasks.isEmpty {
            messages.append("Updated \(updatedTasks.count) task\(updatedTasks.count > 1 ? "s" : "")")
        }
        completionMessage = messages.joined(separator: ", ")
        
        isSaving = false
        flowState = .completed
    }
    
    /// Move to next intent after confirming current one
    func proceedToNextIntent() async {
        let existingTasks = fetchExistingTasks()
        
        // Check if more creates
        if currentCreateIndex + 1 < pendingCreateIntents.count {
            loadCreateIntent(at: currentCreateIndex + 1)
            flowState = .reviewingCreate
            return
        }
        
        // Check if updates remain
        let nextUpdateIndex = flowState == .reviewingCreate ? 0 : currentUpdateIndex + 1
        if nextUpdateIndex < pendingUpdateIntents.count {
            await loadUpdateIntent(at: nextUpdateIndex, existingTasks: existingTasks)
            return
        }
        
        // All done!
        var messages: [String] = []
        if !savedTasks.isEmpty {
            messages.append("Created \(savedTasks.count) task\(savedTasks.count > 1 ? "s" : "")")
        }
        if !updatedTasks.isEmpty {
            messages.append("Updated \(updatedTasks.count) task\(updatedTasks.count > 1 ? "s" : "")")
        }
        completionMessage = messages.joined(separator: ", ")
        flowState = .completed
    }
    
    /// Legacy handler for single create intent
    private func handleCreateTaskIntent(_ intent: CreateTaskIntent) {
        pendingCreateIntents = [intent]
        loadCreateIntent(at: 0)
        flowState = .reviewingCreate
    }
    
    private func handleUpdateTaskIntent(_ intent: UpdateTaskIntent, existingTasks: [RhythmTask]) async {
        updateAction = intent.action
        intentConfidence = intent.confidence
        
        // Find matching tasks
        matchedTasks = findMatchingTasks(for: intent.targetQuery, in: existingTasks)
        
        if matchedTasks.isEmpty {
            // No matching tasks found
            flowState = .error("I couldn't find a task matching '\(intent.targetQuery.rawDescription)'. Could you be more specific?")
        } else if matchedTasks.count == 1 {
            // Single match - proceed directly
            selectedTaskForUpdate = matchedTasks.first
            flowState = .reviewingUpdate
        } else {
            // Multiple matches - ask user to select
            flowState = .selectingTask
        }
    }
    
    // MARK: - Task Matching
    
    private func findMatchingTasks(for query: TaskTargetQuery, in tasks: [RhythmTask]) -> [RhythmTask] {
        var results = tasks
        
        // Filter by status if specified
        if let statusFilter = query.statusFilter {
            results = results.filter { $0.status == statusFilter }
        }
        
        // Filter by priority if specified
        if let priorityFilter = query.priorityFilter {
            results = results.filter { $0.priority == priorityFilter }
        }
        
        // Filter by title keywords
        if let keywords = query.titleKeywords, !keywords.isEmpty {
            results = results.filter { task in
                let titleLower = task.title.lowercased()
                return keywords.contains { keyword in
                    titleLower.contains(keyword.lowercased())
                }
            }
        }
        
        // Filter by time reference
        if let timeRef = query.timeReference {
            let now = Date()
            let calendar = Calendar.current
            
            let timeRefLower = timeRef.lowercased()
            
            if timeRefLower.contains("morning") {
                let startOfMorning = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: now) ?? now
                let endOfMorning = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
                results = results.filter { task in
                    guard let windowStart = task.windowStart else { return false }
                    return windowStart >= startOfMorning && windowStart < endOfMorning
                }
            } else if timeRefLower.contains("afternoon") {
                let startOfAfternoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
                let endOfAfternoon = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now
                results = results.filter { task in
                    guard let windowStart = task.windowStart else { return false }
                    return windowStart >= startOfAfternoon && windowStart < endOfAfternoon
                }
            } else if timeRefLower.contains("evening") || timeRefLower.contains("tonight") {
                let startOfEvening = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now
                let endOfEvening = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
                results = results.filter { task in
                    guard let windowStart = task.windowStart else { return false }
                    return windowStart >= startOfEvening && windowStart < endOfEvening
                }
            }
        }
        
        return results
    }
    
    private func fetchExistingTasks() -> [RhythmTask] {
        guard let context = modelContext else { return [] }
        
        // Fetch non-done tasks
        let predicate = #Predicate<RhythmTask> { task in
            task.statusRaw != "done"
        }
        
        var descriptor = FetchDescriptor<RhythmTask>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.windowStart)]
        descriptor.fetchLimit = 20 // Limit for LLM context
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch tasks: \(error)")
            return []
        }
    }
    
    // MARK: - User Selection Actions
    
    func selectTaskForUpdate(_ task: RhythmTask) {
        selectedTaskForUpdate = task
        flowState = .reviewingUpdate
    }
    
    func setCustomWindow(start: Date, end: Date?) {
        customWindowStart = start
        customWindowEnd = end
        scheduleWindow = ScheduleWindow(
            start: start,
            end: end,
            label: "Custom",
            isFlexible: false
        )
        flowState = .reviewingCreate
    }
    
    func showTimeCustomization() {
        flowState = .customizingTime
    }
    
    // MARK: - Task Creation
    
    /// Create task and optionally proceed to next intent
    func createTask() async {
        await createTaskFromCurrentState()
        
        // Check if there are more intents
        if hasMoreIntents {
            await proceedToNextIntent()
        } else {
            completionMessage = "Created: \(savedTasks.last?.title ?? "")"
            flowState = .completed
        }
    }
    
    /// Create task from current state (internal, doesn't change flow)
    private func createTaskFromCurrentState() async {
        guard let context = modelContext else {
            saveError = "Unable to save. Please try again."
            return
        }
        
        // Create the task
        let task = RhythmTask(
            title: editedTitle.isEmpty ? extractedTitle : editedTitle,
            utteranceText: transcript,
            windowStart: customWindowStart ?? scheduleWindow?.start,
            windowEnd: customWindowEnd ?? scheduleWindow?.end,
            priority: suggestedPriority,
            openingAction: nil
        )
        
        // Set deadline if available
        if let deadline = deadline {
            task.deadline = deadline
        }
        
        // Create and link utterance
        let utterance = Utterance(
            rawText: transcript,
            durationSeconds: speechService.recordingDuration
        )
        utterance.markParsed()
        task.utterance = utterance
        
        // Insert everything
        context.insert(utterance)
        context.insert(task)
        
        do {
            try context.save()
            
            // Log the creation
            eventLogService.logTaskCreated(task)
            
            // Schedule notifications
            await notificationScheduler.scheduleWindowStart(for: task)
            await notificationScheduler.scheduleWindowEnd(for: task)
            
            savedTasks.append(task)
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }
    
    /// Check if there are more intents to process
    var hasMoreIntents: Bool {
        let remainingCreates = pendingCreateIntents.count - currentCreateIndex - 1
        let remainingUpdates = pendingUpdateIntents.count - (flowState == .reviewingCreate ? 0 : currentUpdateIndex + 1)
        return remainingCreates > 0 || remainingUpdates > 0
    }
    
    // MARK: - Task Update
    
    /// Execute update and optionally proceed to next intent
    func executeUpdate() async {
        await executeUpdateFromCurrentState()
        
        // Check if there are more intents
        if hasMoreIntents {
            await proceedToNextIntent()
        } else {
            completionMessage = updateAction?.confirmationMessage ?? "Updated"
            flowState = .completed
        }
    }
    
    /// Execute update from current state (internal, doesn't change flow)
    private func executeUpdateFromCurrentState() async {
        guard let task = selectedTaskForUpdate,
              let action = updateAction,
              let context = modelContext else {
            saveError = "No task selected"
            return
        }
        
        // Get current update intent for parameters
        let currentUpdateIntent = currentUpdateIndex < pendingUpdateIntents.count
            ? pendingUpdateIntents[currentUpdateIndex]
            : nil
        
        // Execute the action
        switch action {
        case .start:
            task.start()
            eventLogService.logTaskStarted(task)
            
        case .pause:
            task.pause()
            eventLogService.logTaskPaused(task)
            
        case .resume:
            task.resume()
            eventLogService.logTaskResumed(task)
            
        case .complete:
            task.complete()
            eventLogService.logTaskCompleted(task)
            
        case .skip:
            task.skip()
            eventLogService.logTaskSkipped(task)
            
        case .delete:
            context.delete(task)
            
        case .snooze:
            let snoozeOption: SnoozeOption
            if let params = currentUpdateIntent?.parameters {
                if let duration = params.snoozeDuration {
                    snoozeOption = SnoozeOption.custom(Int(duration / 60))
                    task.snooze(for: snoozeOption)
                } else if let until = params.snoozeUntil {
                    task.snoozeUntil(until)
                    snoozeOption = .custom(Int(until.timeIntervalSinceNow / 60))
                } else {
                    snoozeOption = .fifteenMinutes
                    task.snooze(for: snoozeOption)
                }
            } else {
                snoozeOption = .fifteenMinutes
                task.snooze(for: snoozeOption)
            }
            eventLogService.logTaskSnoozed(task, option: snoozeOption, newTime: task.windowStart)
            
        case .reschedule:
            if let params = currentUpdateIntent?.parameters,
               let newSchedule = params.newSchedule {
                task.windowStart = newSchedule.start
                task.windowEnd = newSchedule.end
                eventLogService.logTaskRescheduled(task)
            }
        }
        
        do {
            try context.save()
            updatedTasks.append(task)
        } catch {
            saveError = "Couldn't update: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Execute on Multiple Tasks
    
    func executeUpdateOnAllMatched() async {
        guard let action = updateAction,
              let context = modelContext else {
            saveError = "No action to execute"
            return
        }
        
        flowState = .saving
        isSaving = true
        saveError = nil
        
        var successCount = 0
        
        for task in matchedTasks {
            switch action {
            case .start:
                task.start()
                eventLogService.logTaskStarted(task)
            case .pause:
                task.pause()
                eventLogService.logTaskPaused(task)
            case .resume:
                task.resume()
                eventLogService.logTaskResumed(task)
            case .complete:
                task.complete()
                eventLogService.logTaskCompleted(task)
            case .skip:
                task.skip()
                eventLogService.logTaskSkipped(task)
            case .delete:
                context.delete(task)
            case .snooze:
                task.snooze(for: .fifteenMinutes)
                eventLogService.logTaskSnoozed(task, option: .fifteenMinutes, newTime: task.windowStart)
            case .reschedule:
                break // Not supported for batch
            }
            successCount += 1
        }
        
        do {
            try context.save()
            
            updatedTasks = matchedTasks
            completionMessage = "\(action.pastTenseDescription.capitalized) \(successCount) task\(successCount > 1 ? "s" : "")"
            flowState = .completed
        } catch {
            saveError = "Couldn't update: \(error.localizedDescription)"
            flowState = .error(saveError!)
        }
        
        isSaving = false
    }
    
    // MARK: - Reset
    
    func clearErrors() {
        voiceError = nil
        saveError = nil
    }
    
    func reset() {
        flowState = .idle
        transcript = ""
        voiceError = nil
        intentResult = nil
        intentConfidence = 0
        pendingCreateIntents = []
        pendingUpdateIntents = []
        currentCreateIndex = 0
        currentUpdateIndex = 0
        extractedTitle = ""
        editedTitle = ""
        suggestedPriority = .normal
        scheduleWindow = nil
        deadline = nil
        note = nil
        customWindowStart = nil
        customWindowEnd = nil
        updateAction = nil
        matchedTasks = []
        selectedTaskForUpdate = nil
        isSaving = false
        saveError = nil
        savedTasks = []
        updatedTasks = []
        completionMessage = nil
    }
    
    func startNew() {
        reset()
    }
}

// MARK: - Computed Properties

extension QuickAddViewModel {
    /// Whether the current state allows creating a task
    var canCreateTask: Bool {
        guard case .reviewingCreate = flowState else { return false }
        return !editedTitle.isEmpty
    }
    
    /// Whether the current state allows executing update
    var canExecuteUpdate: Bool {
        guard case .reviewingUpdate = flowState else { return false }
        return selectedTaskForUpdate != nil && updateAction != nil
    }
    
    /// Display text for the selected time
    var selectedTimeDescription: String? {
        if let start = customWindowStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return formatter.string(from: start)
        }
        return scheduleWindow?.label
    }
    
    /// Whether voice permissions are available
    var hasVoicePermission: Bool {
        speechService.permissionStatus.canRecord
    }
    
    /// Permission status message
    var permissionMessage: String {
        speechService.permissionStatus.friendlyMessage
    }
    
    /// Whether current intent is create task
    var isCreateIntent: Bool {
        !pendingCreateIntents.isEmpty
    }
    
    /// Whether current intent is update task
    var isUpdateIntent: Bool {
        !pendingUpdateIntents.isEmpty
    }
    
    /// Description of the update action
    var updateActionDescription: String? {
        guard let action = updateAction else { return nil }
        
        if let task = selectedTaskForUpdate {
            return "\(action.displayName) \"\(task.title)\""
        } else if matchedTasks.count > 1 {
            return "\(action.displayName) \(matchedTasks.count) tasks"
        }
        
        return action.displayName
    }
    
    // MARK: - Multi-Intent Properties
    
    /// Total number of intents parsed
    var totalIntentCount: Int {
        pendingCreateIntents.count + pendingUpdateIntents.count
    }
    
    /// Whether multiple intents were parsed
    var hasMultipleIntents: Bool {
        totalIntentCount > 1
    }
    
    /// Current progress through intents (1-based)
    var currentIntentProgress: (current: Int, total: Int) {
        let currentIndex = flowState == .reviewingCreate
            ? currentCreateIndex
            : pendingCreateIntents.count + currentUpdateIndex
        return (currentIndex + 1, totalIntentCount)
    }
    
    /// Summary of all intents for display
    var intentSummary: [(type: String, description: String)] {
        var summary: [(String, String)] = []
        
        for intent in pendingCreateIntents {
            summary.append(("Create", intent.title))
        }
        
        for intent in pendingUpdateIntents {
            summary.append((intent.action.displayName, intent.targetQuery.rawDescription))
        }
        
        return summary
    }
}
