//
//  EventType.swift
//  Rhythm
//
//  All trackable user actions for learning
//

import Foundation

enum EventType: String, Codable, CaseIterable {
    // Task lifecycle
    case taskCreated = "task_created"
    case taskStarted = "task_started"
    case taskPaused = "task_paused"
    case taskResumed = "task_resumed"
    case taskCompleted = "task_completed"
    case taskSkipped = "task_skipped"
    case taskDeleted = "task_deleted"
    
    // Schedule changes
    case taskSnoozed = "task_snoozed"
    case taskRescheduled = "task_rescheduled"
    case windowChanged = "window_changed"
    
    // Voice interactions
    case voiceInputStarted = "voice_input_started"
    case voiceInputCompleted = "voice_input_completed"
    case voiceInputCancelled = "voice_input_cancelled"
    
    // Notifications
    case notificationScheduled = "notification_scheduled"
    case notificationReceived = "notification_received"
    case notificationActioned = "notification_actioned"
    case notificationDismissed = "notification_dismissed"
    
    // Retrospective
    case retrospectiveCompleted = "retrospective_completed"
    
    // App lifecycle
    case appOpened = "app_opened"
    case quickAddOpened = "quick_add_opened"
}

