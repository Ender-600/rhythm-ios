// Rhythm/Services/SyncService.swift
import Foundation
import SwiftData
import Network
import Supabase

@Observable
@MainActor
final class SyncService {
    // MARK: - Published State
    private(set) var isSyncing = false
    private(set) var lastSyncTime: Date?
    private(set) var pendingTaskCount = 0
    private(set) var pendingEventCount = 0
    private(set) var isOnline = true
    private(set) var lastError: SyncError?
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private let client = SupabaseConfig.client
    private let pathMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.rhythm.syncmonitor")
    private nonisolated(unsafe) var syncTimer: Timer?
    private let authService: AuthService
    
    // MARK: - Types
    enum SyncError: LocalizedError {
        case notAuthenticated
        case offline
        case databaseError(String)
        case networkError(String)
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "please sign in first"
            case .offline: return "offline. changes are saved locally"
            case .databaseError(let msg): return "database error: \(msg)"
            case .networkError(let msg): return "network error: \(msg)"
            }
        }
    }
    
    // MARK: - Initialization
    init(authService: AuthService) {
        self.authService = authService
        self.pathMonitor = NWPathMonitor()
        startNetworkMonitoring()
    }
    
    deinit {
        pathMonitor.cancel()
        syncTimer?.invalidate()
    }
    
    // MARK: - Configuration
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await refreshPendingCounts()
        }
        startPeriodicSync()
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = self?.isOnline == false
                self?.isOnline = path.status == .satisfied
                
                if wasOffline && path.status == .satisfied {
                    await self?.syncAll()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }
    
    // MARK: - Periodic Sync
    private func startPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(
            withTimeInterval: 60.0, 
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.syncAll()
            }
        }
    }
    
    // MARK: - Sync Methods
    func syncAll() async {
        guard !isSyncing else { return }
        guard isOnline else {
            lastError = .offline
            return
        }
        guard authService.isAuthenticated else {
            lastError = .notAuthenticated
            return
        }
        guard let context = modelContext else { return }
        
        isSyncing = true
        lastError = nil
        
        do {
            try await syncTasks(context: context)
            try await syncEvents(context: context)
            lastSyncTime = Date()
        } catch let error as SyncError {
            lastError = error
        } catch {
            lastError = .networkError(error.localizedDescription)
        }
        
        await refreshPendingCounts()
        isSyncing = false
    }
    
    // MARK: - Task Sync
    private func syncTasks(context: ModelContext) async throws {
        guard let userId = authService.userId else {
            throw SyncError.notAuthenticated
        }
        
        // get tasks to sync
        let predicate = #Predicate<RhythmTask> { $0.dirtyFlag == true }
        var descriptor = FetchDescriptor<RhythmTask>(predicate: predicate)
        descriptor.fetchLimit = 50
        
        let dirtyTasks = try context.fetch(descriptor)
        
        for task in dirtyTasks {
            do {
                if task.serverId == nil {
                    // create new task
                    try await createTask(task, userId: userId)
                } else {
                    // update task
                    try await updateTask(task, userId: userId)
                }
                
                task.dirtyFlag = false
                task.lastSyncedAt = Date()
            } catch {
                print("Failed to sync task \(task.id): \(error)")
                // continue syncing other tasks
            }
        }
        
        try context.save()
    }
    
    private func createTask(_ task: RhythmTask, userId: UUID) async throws {
        struct TaskRow: Codable {
            let user_id: UUID
            let local_id: UUID
            let title: String
            let utterance_text: String?
            let window_start: Date?
            let window_end: Date?
            let buffer_minutes: Int
            let status: String
            let priority: String
            let snooze_count: Int
            let opening_action: String?
            let total_active_seconds: Double
        }
        
        let row = TaskRow(
            user_id: userId,
            local_id: task.id,
            title: task.title,
            utterance_text: task.utteranceText,
            window_start: task.windowStart,
            window_end: task.windowEnd,
            buffer_minutes: task.bufferMinutes,
            status: task.statusRaw,
            priority: task.priorityRaw,
            snooze_count: task.snoozeCount,
            opening_action: task.openingAction,
            total_active_seconds: task.totalActiveSeconds
        )
        
        let response: [TaskResponse] = try await client.database
            .from("tasks")
            .insert(row)
            .select()
            .execute()
            .value
        
        if let serverId = response.first?.id {
            task.serverId = serverId.uuidString
        }
    }
    
    private func updateTask(_ task: RhythmTask, userId: UUID) async throws {
        guard let serverId = task.serverId else { return }
        
        struct TaskUpdate: Codable {
            let title: String
            let window_start: Date?
            let window_end: Date?
            let status: String
            let priority: String
            let snooze_count: Int
            let total_active_seconds: Double
            let completed_at: Date?
            let updated_at: Date
        }
        
        let update = TaskUpdate(
            title: task.title,
            window_start: task.windowStart,
            window_end: task.windowEnd,
            status: task.statusRaw,
            priority: task.priorityRaw,
            snooze_count: task.snoozeCount,
            total_active_seconds: task.totalActiveSeconds,
            completed_at: task.completedAt,
            updated_at: Date()
        )
        
        try await client.database
            .from("tasks")
            .update(update)
            .eq("id", value: serverId)
            .execute()
    }
    
    // MARK: - Event Sync
    private func syncEvents(context: ModelContext) async throws {
        guard let userId = authService.userId else {
            throw SyncError.notAuthenticated
        }
        
        let predicate = #Predicate<EventLog> { $0.dirtyFlag == true }
        var descriptor = FetchDescriptor<EventLog>(predicate: predicate)
        descriptor.fetchLimit = 100
        
        let dirtyEvents = try context.fetch(descriptor)
        guard !dirtyEvents.isEmpty else { return }
        
        // batch upload events
        struct EventRow: Codable {
            let user_id: UUID
            let local_id: UUID
            let event_type: String
            let occurred_at: Date
            let task_id: UUID?
            let metadata: String?
            let timezone: String
        }
        
        let eventRows = dirtyEvents.map { event in
            EventRow(
                user_id: userId,
                local_id: event.id,
                event_type: event.eventType,
                occurred_at: event.occurredAt,
                task_id: event.taskId,
                metadata: event.metadata,
                timezone: event.timezone
            )
        }
        
        try await client.database
            .from("event_logs")
            .insert(eventRows)
            .execute()
        
        // mark as synced
        for event in dirtyEvents {
            event.markUploaded()
        }
        
        try context.save()
    }
    
    // MARK: - Pending Counts
    func refreshPendingCounts() async {
        guard let context = modelContext else {
            pendingTaskCount = 0
            pendingEventCount = 0
            return
        }
        
        let taskPredicate = #Predicate<RhythmTask> { $0.dirtyFlag == true }
        var taskDescriptor = FetchDescriptor<RhythmTask>(predicate: taskPredicate)
        taskDescriptor.propertiesToFetch = []
        
        let eventPredicate = #Predicate<EventLog> { $0.dirtyFlag == true }
        var eventDescriptor = FetchDescriptor<EventLog>(predicate: eventPredicate)
        eventDescriptor.propertiesToFetch = []
        
        do {
            pendingTaskCount = try context.fetchCount(taskDescriptor)
            pendingEventCount = try context.fetchCount(eventDescriptor)
        } catch {
            pendingTaskCount = 0
            pendingEventCount = 0
        }
    }
}

// MARK: - Response Types
private struct TaskResponse: Codable {
    let id: UUID
}
