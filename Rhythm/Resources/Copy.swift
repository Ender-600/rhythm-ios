//
//  Copy.swift
//  Rhythm
//
//  All UI copy - gentle, invitational, never commanding
//  Following the principle: suggest, don't demand
//

import Foundation

enum Copy {
    // MARK: - App-wide
    
    static let appName = "Rhythm"
    static let tagline = "Plan gently, act when ready"
    
    // MARK: - Quick Add
    
    enum QuickAdd {
        static let prompt = "What would you like to do?"
        static let voiceHint = "Tap or hold to speak"
        static let voiceRecording = "Listening..."
        static let voiceProcessing = "Understanding..."
        static let typingPlaceholder = "Or type here..."
        
        static let signalsHeader = "I noticed these plans:"
        static let timeHeader = "When works for you?"
        static let tagsHeader = "Tags"
        static let createButton = "Add to my rhythm"
        static let cancelButton = "Not now"
        
        static let successTitle = "Added!"
        static let successMessage = "I'll remind you when it's time."
        static let addAnother = "Add another"
        
        // Errors
        static let permissionNeeded = "Voice input needs your permission. You can enable it in Settings."
        static let noTranscript = "I didn't catch that. Want to try again?"
        static let saveFailed = "Couldn't save that. Want to try again?"
    }
    
    // MARK: - Plan View
    
    enum Plan {
        static let title = "Your Rhythm"
        static let emptyDay = "Your day is wide open"
        static let emptyWeek = "A quiet week ahead"
        static let emptyMonth = "Plenty of space this month"
        
        static let urgentSection = "Urgent"
        static let normalSection = "Normal"
        static let lowSection = "Low Priority"
        
        static let nextUp = "Next up"
        static let inProgress = "Working on"
        static let comingSoon = "Coming soon"
        
        static let morningGreeting = "Good morning"
        static let afternoonGreeting = "Good afternoon"
        static let eveningGreeting = "Good evening"
    }
    
    // MARK: - Tasks View
    
    enum Tasks {
        static let title = "Tasks"
        static let notStartedColumn = "Not Started"
        static let inProgressColumn = "In Progress"
        static let doneColumn = "Done"
        
        static let empty = "No tasks yet"
        static let allDone = "All caught up!"
        
        // Actions (gentle)
        static let startAction = "Start"
        static let pauseAction = "Pause"
        static let resumeAction = "Continue"
        static let completeAction = "Done!"
        static let skipAction = "Not today"
        static let snoozeAction = "Later"
        static let deleteAction = "Remove"
    }
    
    // MARK: - Snooze
    
    enum Snooze {
        static let title = "When would be better?"
        static let subtitle = "No worries - let's find a better time"
        
        static func option(_ option: SnoozeOption) -> String {
            option.gentleLabel
        }
        
        static let customPrompt = "Pick your own time"
        static let confirm = "Sounds good"
        static let cancel = "Never mind"
    }
    
    // MARK: - Completion
    
    enum Completion {
        static let title = "Nice work!"
        static let subtitle = "How did that go?"
        
        static let durationQuestion = "How long did it actually take?"
        static let feelingQuestion = "How are you feeling?"
        static let notesPlaceholder = "Any notes for next time?"
        
        static let saveButton = "Save & close"
        static let skipButton = "Just mark done"
        
        // Quick feelings
        static let feelingGreat = "Feeling great"
        static let feelingOkay = "It was okay"
        static let feelingDrained = "Pretty drained"
    }
    
    // MARK: - Notifications
    
    enum Notifications {
        static let morningPreviewTitle = "Good morning ☀️"
        
        static func morningPreviewBody(taskCount: Int, topTask: String?) -> String {
            if taskCount == 0 {
                return "Your day is wide open. What would you like to focus on?"
            } else if taskCount == 1, let task = topTask {
                return "One thing on your radar: \(task)"
            } else if let task = topTask {
                return "You have \(taskCount) things planned. Starting with: \(task)"
            } else {
                return "You have \(taskCount) things planned. Ready to see your rhythm?"
            }
        }
        
        static func windowStartTitle(_ taskTitle: String) -> String {
            "Ready for \(taskTitle)?"
        }
        
        static func windowStartBody(openingAction: String?) -> String {
            if let action = openingAction {
                return "Start with: \(action)"
            }
            return "Your window is opening up. Ready when you are."
        }
        
        static func windowEndTitle(_ taskTitle: String) -> String {
            "How did \(taskTitle) go?"
        }
        
        static let windowEndBody = "Your window is wrapping up. Did you get to it?"
        
        static func snoozeReminderTitle(_ taskTitle: String) -> String {
            "Back to \(taskTitle)?"
        }
        
        static let snoozeReminderBody = "Your snooze is up. Ready to give it another go?"
    }
    
    // MARK: - Settings
    
    enum Settings {
        static let title = "Settings"
        static let notificationsSection = "Notifications"
        static let morningPreviewTime = "Morning preview time"
        static let soundsEnabled = "Notification sounds"
        
        static let appearanceSection = "Appearance"
        static let darkMode = "Dark mode"
        
        static let dataSection = "Your Data"
        static let syncStatus = "Sync status"
        static let exportData = "Export my data"
        static let clearCompleted = "Clear old completed tasks"
        
        static let aboutSection = "About"
        static let version = "Version"
        static let feedback = "Send feedback"
        static let privacy = "Privacy policy"
    }
    
    // MARK: - Memory (Placeholder)
    
    enum Memory {
        static let title = "Memory"
        static let subtitle = "Your patterns and insights"
        static let comingSoon = "Coming soon..."
        static let teaser = "Rhythm will learn your patterns and help you understand your productivity rhythms."
    }
    
    // MARK: - Empty States
    
    enum EmptyState {
        static let noTasksTitle = "Ready when you are"
        static let noTasksMessage = "Tap the mic to add your first task"
        static let noTasksButton = "Add a task"
        
        static let offlineTitle = "You're offline"
        static let offlineMessage = "Your changes are saved locally and will sync when you're back online."
    }
    
    // MARK: - Errors
    
    enum Error {
        static let genericTitle = "Something went wrong"
        static let genericMessage = "That didn't work. Want to try again?"
        static let retryButton = "Try again"
        static let dismissButton = "Okay"
        
        static let permissionTitle = "Permission needed"
        static let permissionMessage = "To use this feature, please enable it in Settings."
        static let openSettings = "Open Settings"
    }
}

// MARK: - Time-based Greetings

extension Copy {
    static var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<12:
            return Plan.morningGreeting
        case 12..<17:
            return Plan.afternoonGreeting
        default:
            return Plan.eveningGreeting
        }
    }
}

