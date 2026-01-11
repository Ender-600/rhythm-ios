//
//  QuickAddIntent.swift
//  Rhythm
//
//  App Intent for Action Button integration
//  Opens Quick Add and starts voice capture
//

import AppIntents
import SwiftUI

/// App Intent that opens Quick Add and starts voice capture
/// Can be triggered via Shortcuts or Action Button
struct QuickAddIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Task"
    static var description = IntentDescription("Add a task using voice input")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Post notification to trigger voice capture
        NotificationCenter.default.post(
            name: .quickAddIntentTriggered,
            object: nil
        )
        
        return .result()
    }
}

/// Shortcut for adding a task with a specific title
struct AddTaskWithTitleIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Add a task with a specific title")
    
    @Parameter(title: "Task Title")
    var taskTitle: String
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Post notification with the title
        NotificationCenter.default.post(
            name: .addTaskIntentTriggered,
            object: nil,
            userInfo: ["title": taskTitle]
        )
        
        return .result()
    }
}

// MARK: - App Shortcuts Provider

struct RhythmShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickAddIntent(),
            phrases: [
                "Add task with \(.applicationName)",
                "Quick add in \(.applicationName)",
                "New task in \(.applicationName)",
                "Add to \(.applicationName)"
            ],
            shortTitle: "Quick Add",
            systemImageName: "mic.fill"
        )
        
        AppShortcut(
            intent: AddTaskWithTitleIntent(),
            phrases: [
                "Add task to \(.applicationName)",
                "Create task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus"
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let quickAddIntentTriggered = Notification.Name("quickAddIntentTriggered")
    static let addTaskIntentTriggered = Notification.Name("addTaskIntentTriggered")
}

