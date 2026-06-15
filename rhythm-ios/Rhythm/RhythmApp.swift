//
//  RhythmApp.swift
//  Rhythm
//
//  AI productivity app that gives a sense of planning first,
//  then gently nudges action.
//

import SwiftUI
import SwiftData

@main
struct RhythmApp: App {
    // MARK: - SwiftData Model Container
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RhythmTask.self,
            Utterance.self,
            Tag.self,
            TaskScheduleChange.self,
            EventLog.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Local-only for MVP, sync handled manually
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Services (Singleton instances)
    
    @State private var speechService = SpeechService()
    @State private var eventLogService = EventLogService()
    @State private var notificationScheduler = NotificationScheduler()
    
    // MARK: - App State
    
    @State private var mainTabView: MainTabView?
    @State private var authService: AuthService
    @State private var syncService: SyncService
    
    init() {
        let auth = AuthService()
        _authService = State(initialValue: auth)
        _syncService = State(initialValue: SyncService(authService: auth))
    }
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView(
                    speechService: speechService,
                    eventLogService: eventLogService,
                    notificationScheduler: notificationScheduler,
                    syncService: syncService
                )
                .modelContainer(sharedModelContainer)
                .onAppear {
                    setupApp()
                    syncService.configure(with: sharedModelContainer.mainContext)
                }
                .onReceive(NotificationCenter.default.publisher(for: .quickAddIntentTriggered)) { _ in
                    // Handle Quick Add intent
                    handleQuickAddIntent()
                }
                .onReceive(NotificationCenter.default.publisher(for: .addTaskIntentTriggered)) { notification in
                    // Handle Add Task intent with title
                    if let title = notification.userInfo?["title"] as? String {
                        handleAddTaskIntent(title: title)
                    }
                }
            } else {
                AuthView(authService: authService)
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupApp() {
        // Request notification permissions
        Task {
            _ = await notificationScheduler.requestAuthorization()
        }
        
        // Check speech permissions
        Task {
            await speechService.checkPermissions()
        }
        
        // Schedule morning preview (if enabled)
        Task {
            await scheduleMorningPreview()
        }
    }
    
    private func scheduleMorningPreview() async {
        // Get task count for preview
        let context = sharedModelContainer.mainContext
        
        let notDonePredicate = #Predicate<RhythmTask> { task in
            task.statusRaw != "done"
        }
        
        var descriptor = FetchDescriptor<RhythmTask>(predicate: notDonePredicate)
        descriptor.sortBy = [SortDescriptor(\.windowStart)]
        descriptor.fetchLimit = 1
        
        do {
            let tasks = try context.fetch(descriptor)
            let countDescriptor = FetchDescriptor<RhythmTask>(predicate: notDonePredicate)
            let totalCount = try context.fetchCount(countDescriptor)
            
            await notificationScheduler.scheduleMorningPreview(
                taskCount: totalCount,
                topTaskTitle: tasks.first?.title
            )
        } catch {
            print("Failed to schedule morning preview: \(error)")
        }
    }
    
    // MARK: - Intent Handlers
    
    private func handleQuickAddIntent() {
        // Switch to Quick Add tab and start voice
        // This will be handled by MainTabView via notification
    }
    
    private func handleAddTaskIntent(title: String) {
        // Create a task directly with the given title
        let context = sharedModelContainer.mainContext
        let task = RhythmTask(title: title)
        context.insert(task)
        
        do {
            try context.save()
            eventLogService.logTaskCreated(task)
        } catch {
            print("Failed to create task from intent: \(error)")
        }
    }
}

// MARK: - App Delegate for Push Notifications (Future)

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Setup for push notifications would go here
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Handle device token for APNs (future)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
}
#endif
