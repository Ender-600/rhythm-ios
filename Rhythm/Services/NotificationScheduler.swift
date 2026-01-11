//
//  NotificationScheduler.swift
//  Rhythm
//
//  Schedules local notifications for the Preview → Invite rhythm
//  Never commanding - always invitational and gentle
//

import Foundation
import UserNotifications

@Observable
final class NotificationScheduler: @unchecked Sendable {
    // MARK: - Published State
    
    private(set) var isAuthorized = false
    private(set) var pendingNotifications: [UNNotificationRequest] = []
    
    // MARK: - Private Properties
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Notification Types
    
    enum NotificationType: String {
        case morningPreview = "morning_preview"
        case windowStart = "window_start"
        case windowEnd = "window_end"
        case snoozeReminder = "snooze_reminder"
        
        var categoryIdentifier: String {
            "rhythm_\(rawValue)"
        }
    }
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkAuthorization()
            await registerCategories()
        }
    }
    
    // MARK: - Authorization
    
    @MainActor
    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            
            if granted {
                await registerCategories()
            }
            
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    // MARK: - Category Registration
    
    private func registerCategories() async {
        // Morning preview actions
        let viewPlanAction = UNNotificationAction(
            identifier: "view_plan",
            title: "See my day",
            options: .foreground
        )
        
        let morningCategory = UNNotificationCategory(
            identifier: NotificationType.morningPreview.categoryIdentifier,
            actions: [viewPlanAction],
            intentIdentifiers: []
        )
        
        // Window start actions
        let startAction = UNNotificationAction(
            identifier: "start_task",
            title: "Let's do it",
            options: .foreground
        )
        
        let snooze10Action = UNNotificationAction(
            identifier: "snooze_10",
            title: "10 more minutes",
            options: []
        )
        
        let snooze30Action = UNNotificationAction(
            identifier: "snooze_30",
            title: "30 more minutes",
            options: []
        )
        
        let windowStartCategory = UNNotificationCategory(
            identifier: NotificationType.windowStart.categoryIdentifier,
            actions: [startAction, snooze10Action, snooze30Action],
            intentIdentifiers: []
        )
        
        // Window end actions
        let doneAction = UNNotificationAction(
            identifier: "mark_done",
            title: "Done!",
            options: []
        )
        
        let moreTimeAction = UNNotificationAction(
            identifier: "need_more_time",
            title: "Need more time",
            options: .foreground
        )
        
        let skipAction = UNNotificationAction(
            identifier: "skip_task",
            title: "Not today",
            options: .destructive
        )
        
        let windowEndCategory = UNNotificationCategory(
            identifier: NotificationType.windowEnd.categoryIdentifier,
            actions: [doneAction, moreTimeAction, skipAction],
            intentIdentifiers: []
        )
        
        center.setNotificationCategories([
            morningCategory,
            windowStartCategory,
            windowEndCategory
        ])
    }
    
    // MARK: - Schedule Notifications
    
    /// Schedule morning preview notification
    func scheduleMorningPreview(
        taskCount: Int,
        topTaskTitle: String?,
        at time: DateComponents? = nil
    ) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Good morning ☀️"
        
        if taskCount == 0 {
            content.body = "Your day is wide open. What would you like to focus on?"
        } else if taskCount == 1, let title = topTaskTitle {
            content.body = "You have one thing on your radar: \(title)"
        } else if let title = topTaskTitle {
            content.body = "You have \(taskCount) things planned. Starting with: \(title)"
        } else {
            content.body = "You have \(taskCount) things planned. Ready to see your rhythm?"
        }
        
        content.sound = .default
        content.categoryIdentifier = NotificationType.morningPreview.categoryIdentifier
        
        var triggerComponents = time ?? DateComponents()
        if triggerComponents.hour == nil {
            triggerComponents.hour = AppConfig.morningPreviewHour
            triggerComponents.minute = AppConfig.morningPreviewMinute
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "morning_preview",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule morning preview: \(error)")
        }
    }
    
    /// Schedule window start notification (invite style)
    func scheduleWindowStart(for task: RhythmTask) async {
        guard isAuthorized, let windowStart = task.windowStart else { return }
        
        // Schedule notification a few minutes before window starts
        let notificationTime = windowStart.addingTimeInterval(
            -Double(AppConfig.windowReminderMinutesBefore * 60)
        )
        
        guard notificationTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Ready for \(task.title)?"
        
        if let openingAction = task.openingAction {
            content.body = "Start with: \(openingAction)"
        } else {
            content.body = "Your window is opening up. Want to dive in?"
        }
        
        content.sound = .default
        content.categoryIdentifier = NotificationType.windowStart.categoryIdentifier
        content.userInfo = ["taskId": task.id.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: notificationTime.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "window_start_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule window start: \(error)")
        }
    }
    
    /// Schedule window end check-in
    func scheduleWindowEnd(for task: RhythmTask) async {
        guard isAuthorized, let windowEnd = task.windowEnd else { return }
        guard windowEnd > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "How did \(task.title) go?"
        content.body = "Your window is wrapping up. Did you get to it?"
        content.sound = .default
        content.categoryIdentifier = NotificationType.windowEnd.categoryIdentifier
        content.userInfo = ["taskId": task.id.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: windowEnd.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "window_end_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule window end: \(error)")
        }
    }
    
    /// Schedule snooze reminder
    func scheduleSnoozeReminder(for task: RhythmTask, at time: Date) async {
        guard isAuthorized, time > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Back to \(task.title)?"
        content.body = "Your snooze is up. Ready to give it another go?"
        content.sound = .default
        content.categoryIdentifier = NotificationType.windowStart.categoryIdentifier
        content.userInfo = ["taskId": task.id.uuidString]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: time.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "snooze_\(task.id.uuidString)_\(Int(time.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule snooze reminder: \(error)")
        }
    }
    
    // MARK: - Manage Notifications
    
    /// Cancel all notifications for a task
    func cancelNotifications(for taskId: UUID) {
        let identifiers = [
            "window_start_\(taskId.uuidString)",
            "window_end_\(taskId.uuidString)"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // Also remove any snooze reminders
        Task {
            let pending = await center.pendingNotificationRequests()
            let snoozeIds = pending
                .filter { $0.identifier.starts(with: "snooze_\(taskId.uuidString)") }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: snoozeIds)
        }
    }
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Refresh the list of pending notifications
    @MainActor
    func refreshPendingNotifications() async {
        pendingNotifications = await center.pendingNotificationRequests()
    }
    
    /// Reschedule notifications for a task (after snooze/reschedule)
    func rescheduleNotifications(for task: RhythmTask) async {
        cancelNotifications(for: task.id)
        
        if task.status != .done {
            await scheduleWindowStart(for: task)
            await scheduleWindowEnd(for: task)
        }
    }
}

// MARK: - Notification Content Helpers

extension NotificationScheduler {
    /// Generate gentle, varied notification copy
    static func gentleWindowStartCopy(for task: RhythmTask) -> (title: String, body: String) {
        let titles = [
            "Ready for \(task.title)?",
            "Time for \(task.title)",
            "\(task.title) window is here",
            "Your \(task.title) time"
        ]
        
        let bodies: [String]
        if let opening = task.openingAction {
            bodies = [
                "Start with: \(opening)",
                "First step: \(opening)",
                "Begin by: \(opening)"
            ]
        } else {
            bodies = [
                "Your window is opening up",
                "Ready when you are",
                "A good time to start"
            ]
        }
        
        return (
            titles.randomElement() ?? titles[0],
            bodies.randomElement() ?? bodies[0]
        )
    }
}

