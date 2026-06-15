//
//  VoiceIntent.swift
//  Rhythm
//
//  Voice intent models for LLM-parsed user commands
//  Supports multiple intents in a single utterance (create + update)
//

import Foundation

// MARK: - Voice Intent Result (Top Level)

/// Represents all parsed intents from user's voice input
/// A single utterance can contain multiple intents
struct VoiceIntentResult: Codable {
    /// Tasks to create
    let createIntents: [CreateTaskIntent]
    
    /// Tasks to update
    let updateIntents: [UpdateTaskIntent]
    
    /// Raw utterance for reference
    let rawUtterance: String
    
    /// Overall confidence score
    let confidence: Double
    
    /// Whether any intents were parsed
    var hasIntents: Bool {
        !createIntents.isEmpty || !updateIntents.isEmpty
    }
    
    /// Total number of intents
    var totalIntentCount: Int {
        createIntents.count + updateIntents.count
    }
    
    /// Whether this has only create intents
    var isCreateOnly: Bool {
        !createIntents.isEmpty && updateIntents.isEmpty
    }
    
    /// Whether this has only update intents
    var isUpdateOnly: Bool {
        createIntents.isEmpty && !updateIntents.isEmpty
    }
    
    /// Whether this has mixed intents
    var isMixed: Bool {
        !createIntents.isEmpty && !updateIntents.isEmpty
    }
    
    /// Empty result
    static func empty(utterance: String) -> VoiceIntentResult {
        VoiceIntentResult(
            createIntents: [],
            updateIntents: [],
            rawUtterance: utterance,
            confidence: 0
        )
    }
}

// MARK: - Legacy Single Intent (for backward compatibility)

/// Single intent enum for simpler cases
enum VoiceIntent: Codable {
    case createTask(CreateTaskIntent)
    case updateTask(UpdateTaskIntent)
    case unknown(String)
    
    var isCreateTask: Bool {
        if case .createTask = self { return true }
        return false
    }
    
    var isUpdateTask: Bool {
        if case .updateTask = self { return true }
        return false
    }
}

// MARK: - Create Task Intent

/// Intent to create a new task
struct CreateTaskIntent: Codable {
    /// Task title (required)
    let title: String
    
    /// Suggested schedule window
    let scheduleWindow: ScheduleWindow?
    
    /// Deadline if mentioned
    let deadline: Date?
    
    /// Priority level (defaults to normal)
    let priority: TaskPriority
    
    /// Optional note/description
    let note: String?
    
    /// Raw utterance for reference
    let rawUtterance: String
    
    /// Confidence score (0-1)
    let confidence: Double
    
    /// Whether the intent has minimum required info
    var isValid: Bool {
        !title.isEmpty && (scheduleWindow != nil || deadline != nil)
    }
    
    /// Whether only title was extracted (minimal info)
    var isMinimal: Bool {
        scheduleWindow == nil && deadline == nil
    }
}

/// Schedule window parsed from user's voice
struct ScheduleWindow: Codable {
    let start: Date?
    let end: Date?
    let label: String // "this evening", "tomorrow morning", etc.
    let isFlexible: Bool // "around 3pm" vs "at 3pm"
    
    /// Description for display
    var displayDescription: String {
        if let start = start {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return formatter.string(from: start)
        }
        return label
    }
}

// MARK: - Update Task Intent

/// Intent to update an existing task
struct UpdateTaskIntent: Codable {
    /// The action to perform
    let action: TaskAction
    
    /// How to identify the target task(s)
    let targetQuery: TaskTargetQuery
    
    /// Additional parameters for certain actions
    let parameters: ActionParameters?
    
    /// Raw utterance for reference
    let rawUtterance: String
    
    /// Confidence score (0-1)
    let confidence: Double
}

/// Actions that can be performed on tasks
enum TaskAction: String, Codable, CaseIterable {
    case start = "task_started"
    case pause = "task_paused"
    case resume = "task_resumed"
    case complete = "task_completed"
    case skip = "task_skipped"
    case delete = "task_deleted"
    case snooze = "task_snoozed"
    case reschedule = "task_rescheduled"
    
    var displayName: String {
        switch self {
        case .start: return "Start"
        case .pause: return "Pause"
        case .resume: return "Resume"
        case .complete: return "Complete"
        case .skip: return "Skip"
        case .delete: return "Delete"
        case .snooze: return "Snooze"
        case .reschedule: return "Reschedule"
        }
    }
    
    var pastTenseDescription: String {
        switch self {
        case .start: return "started"
        case .pause: return "paused"
        case .resume: return "resumed"
        case .complete: return "completed"
        case .skip: return "skipped"
        case .delete: return "deleted"
        case .snooze: return "snoozed"
        case .reschedule: return "rescheduled"
        }
    }
    
    var confirmationMessage: String {
        switch self {
        case .start: return "Let's get started!"
        case .pause: return "Taking a break"
        case .resume: return "Picking up where you left off"
        case .complete: return "Nice work! ✓"
        case .skip: return "Skipped for now"
        case .delete: return "Removed"
        case .snooze: return "Snoozed"
        case .reschedule: return "Rescheduled"
        }
    }
}

/// How to identify the target task(s)
struct TaskTargetQuery: Codable {
    /// Keywords from task title
    let titleKeywords: [String]?
    
    /// Reference like "my first task", "the meeting task"
    let reference: String?
    
    /// Time-based reference like "the task for this afternoon"
    let timeReference: String?
    
    /// Status filter like "all in progress tasks"
    let statusFilter: TaskStatus?
    
    /// Priority filter
    let priorityFilter: TaskPriority?
    
    /// Whether this targets multiple tasks
    let isMultiple: Bool
    
    /// Original text describing the target
    let rawDescription: String
}

/// Additional parameters for certain actions
struct ActionParameters: Codable {
    /// For snooze: how long to snooze
    let snoozeDuration: TimeInterval?
    
    /// For snooze: specific time to snooze until
    let snoozeUntil: Date?
    
    /// For reschedule: new schedule window
    let newSchedule: ScheduleWindow?
    
    /// For any action: reason/note
    let reason: String?
}

// MARK: - LLM Response Structure

/// The structure we expect back from the LLM (supports multiple intents)
struct LLMIntentResponse: Codable {
    /// List of tasks to create
    let createTasks: [LLMCreateTaskData]?
    
    /// List of tasks to update
    let updateTasks: [LLMUpdateTaskData]?
    
    /// Overall confidence
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case createTasks = "create_tasks"
        case updateTasks = "update_tasks"
        case confidence
    }
    
    // Legacy single-intent support
    var intentType: String {
        if let creates = createTasks, !creates.isEmpty, (updateTasks ?? []).isEmpty {
            return "create_task"
        } else if let updates = updateTasks, !updates.isEmpty, (createTasks ?? []).isEmpty {
            return "update_task"
        } else if (createTasks ?? []).isEmpty && (updateTasks ?? []).isEmpty {
            return "unknown"
        } else {
            return "mixed"
        }
    }
}

struct LLMCreateTaskData: Codable {
    let title: String
    let scheduleDescription: String?
    let scheduleStart: String? // ISO8601 date string
    let scheduleEnd: String?
    let deadline: String? // ISO8601 date string
    let priority: String? // "urgent", "normal", "low"
    let note: String?
    let isFlexible: Bool?
    
    enum CodingKeys: String, CodingKey {
        case title
        case scheduleDescription = "schedule_description"
        case scheduleStart = "schedule_start"
        case scheduleEnd = "schedule_end"
        case deadline
        case priority
        case note
        case isFlexible = "is_flexible"
    }
}

struct LLMUpdateTaskData: Codable {
    let action: String // TaskAction raw value
    let targetDescription: String
    let titleKeywords: [String]?
    let timeReference: String?
    let statusFilter: String?
    let isMultiple: Bool?
    let snoozeDuration: Int? // minutes
    let snoozeUntil: String? // ISO8601
    let newScheduleDescription: String?
    let newScheduleStart: String?
    let newScheduleEnd: String?
    let reason: String?
    
    enum CodingKeys: String, CodingKey {
        case action
        case targetDescription = "target_description"
        case titleKeywords = "title_keywords"
        case timeReference = "time_reference"
        case statusFilter = "status_filter"
        case isMultiple = "is_multiple"
        case snoozeDuration = "snooze_duration"
        case snoozeUntil = "snooze_until"
        case newScheduleDescription = "new_schedule_description"
        case newScheduleStart = "new_schedule_start"
        case newScheduleEnd = "new_schedule_end"
        case reason
    }
}

// MARK: - Intent Parsing Helpers

extension LLMIntentResponse {
    /// Convert LLM response to VoiceIntentResult (supports multiple intents)
    func toVoiceIntentResult(rawUtterance: String) -> VoiceIntentResult {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Parse all create intents
        var createIntents: [CreateTaskIntent] = []
        if let createTasks = createTasks {
            for data in createTasks {
                // Parse schedule window
                var scheduleWindow: ScheduleWindow? = nil
                if let desc = data.scheduleDescription {
                    let startDate = data.scheduleStart.flatMap { dateFormatter.date(from: $0) }
                    let endDate = data.scheduleEnd.flatMap { dateFormatter.date(from: $0) }
                    scheduleWindow = ScheduleWindow(
                        start: startDate,
                        end: endDate,
                        label: desc,
                        isFlexible: data.isFlexible ?? false
                    )
                }
                
                // Parse deadline
                let deadline = data.deadline.flatMap { dateFormatter.date(from: $0) }
                
                // Parse priority
                let priority = TaskPriority(rawValue: data.priority ?? "normal") ?? .normal
                
                let intent = CreateTaskIntent(
                    title: data.title,
                    scheduleWindow: scheduleWindow,
                    deadline: deadline,
                    priority: priority,
                    note: data.note,
                    rawUtterance: rawUtterance,
                    confidence: confidence
                )
                createIntents.append(intent)
            }
        }
        
        // Parse all update intents
        var updateIntents: [UpdateTaskIntent] = []
        if let updateTasks = updateTasks {
            for data in updateTasks {
                guard let action = TaskAction(rawValue: data.action) else { continue }
                
                // Parse target query
                let statusFilter = data.statusFilter.flatMap { TaskStatus(rawValue: $0) }
                let targetQuery = TaskTargetQuery(
                    titleKeywords: data.titleKeywords,
                    reference: nil,
                    timeReference: data.timeReference,
                    statusFilter: statusFilter,
                    priorityFilter: nil,
                    isMultiple: data.isMultiple ?? false,
                    rawDescription: data.targetDescription
                )
                
                // Parse action parameters
                var parameters: ActionParameters? = nil
                if action == .snooze || action == .reschedule {
                    var newSchedule: ScheduleWindow? = nil
                    if let desc = data.newScheduleDescription {
                        let startDate = data.newScheduleStart.flatMap { dateFormatter.date(from: $0) }
                        let endDate = data.newScheduleEnd.flatMap { dateFormatter.date(from: $0) }
                        newSchedule = ScheduleWindow(
                            start: startDate,
                            end: endDate,
                            label: desc,
                            isFlexible: false
                        )
                    }
                    
                    let snoozeUntil = data.snoozeUntil.flatMap { dateFormatter.date(from: $0) }
                    let snoozeDuration = data.snoozeDuration.map { TimeInterval($0 * 60) }
                    
                    parameters = ActionParameters(
                        snoozeDuration: snoozeDuration,
                        snoozeUntil: snoozeUntil,
                        newSchedule: newSchedule,
                        reason: data.reason
                    )
                }
                
                let intent = UpdateTaskIntent(
                    action: action,
                    targetQuery: targetQuery,
                    parameters: parameters,
                    rawUtterance: rawUtterance,
                    confidence: confidence
                )
                updateIntents.append(intent)
            }
        }
        
        return VoiceIntentResult(
            createIntents: createIntents,
            updateIntents: updateIntents,
            rawUtterance: rawUtterance,
            confidence: confidence
        )
    }
    
    /// Convert to single VoiceIntent (legacy support, uses first intent only)
    func toVoiceIntent(rawUtterance: String) -> VoiceIntent {
        let result = toVoiceIntentResult(rawUtterance: rawUtterance)
        
        if let firstCreate = result.createIntents.first {
            return .createTask(firstCreate)
        } else if let firstUpdate = result.updateIntents.first {
            return .updateTask(firstUpdate)
        } else {
            return .unknown(rawUtterance)
        }
    }
}
