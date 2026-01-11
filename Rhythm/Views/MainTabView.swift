//
//  MainTabView.swift
//  Rhythm
//
//  Main tab navigation for the app
//  Quick Add is the center tab with prominent styling
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Services (injected from app)
    let speechService: SpeechService
    let eventLogService: EventLogService
    let notificationScheduler: NotificationScheduler
    let syncService: SyncService
    
    // State
    @State private var selectedTab: Tab = .plan
    @State private var quickAddViewModel: QuickAddViewModel?
    @State private var planViewModel: PlanViewModel?
    @State private var tasksViewModel: TasksViewModel?
    
    enum Tab: String, CaseIterable {
        case plan = "Plan"
        case tasks = "Tasks"
        case quickAdd = "Add"
        case memory = "Memory"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .plan: return "calendar"
            case .tasks: return "checklist"
            case .quickAdd: return "mic.fill"
            case .memory: return "brain.head.profile"
            case .settings: return "gear"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .plan: return "calendar"
            case .tasks: return "checklist"
            case .quickAdd: return "mic.fill"
            case .memory: return "brain.head.profile"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Plan tab
            if let planVM = planViewModel {
                PlanView(viewModel: planVM)
                    .tabItem {
                        Label(Tab.plan.rawValue, systemImage: Tab.plan.icon)
                    }
                    .tag(Tab.plan)
            }
            
            // Tasks tab
            if let tasksVM = tasksViewModel {
                TasksView(viewModel: tasksVM)
                    .tabItem {
                        Label(Tab.tasks.rawValue, systemImage: Tab.tasks.icon)
                    }
                    .tag(Tab.tasks)
            }
            
            // Quick Add tab (center, prominent)
            if let quickAddVM = quickAddViewModel {
                QuickAddView(viewModel: quickAddVM)
                    .tabItem {
                        Label(Tab.quickAdd.rawValue, systemImage: Tab.quickAdd.icon)
                    }
                    .tag(Tab.quickAdd)
            }
            
            // Memory tab
            MemoryView()
                .tabItem {
                    Label(Tab.memory.rawValue, systemImage: Tab.memory.icon)
                }
                .tag(Tab.memory)
            
            // Settings tab
            SettingsView(syncService: syncService)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(.rhythmCoral)
        .onAppear {
            setupViewModels()
            configureTabBarAppearance()
            
            // Log app open
            eventLogService.logAppOpened()
        }
    }
    
    private func setupViewModels() {
        // Quick Add
        if quickAddViewModel == nil {
            let vm = QuickAddViewModel(
                speechService: speechService,
                eventLogService: eventLogService,
                notificationScheduler: notificationScheduler
            )
            vm.configure(with: modelContext)
            quickAddViewModel = vm
        }
        
        // Plan
        if planViewModel == nil {
            let vm = PlanViewModel(
                notificationScheduler: notificationScheduler,
                eventLogService: eventLogService
            )
            vm.configure(with: modelContext)
            planViewModel = vm
        }
        
        // Tasks
        if tasksViewModel == nil {
            let vm = TasksViewModel(
                eventLogService: eventLogService,
                notificationScheduler: notificationScheduler
            )
            vm.configure(with: modelContext)
            tasksViewModel = vm
        }
        
        // Configure services that need model context
        eventLogService.configure(with: modelContext)
        syncService.configure(with: modelContext)
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Customize colors
        let normalColor = UIColor(Color.rhythmTextSecondary)
        let selectedColor = UIColor(Color.rhythmCoral)
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // MARK: - Public Methods for Deep Linking
    
    func openQuickAdd() {
        selectedTab = .quickAdd
    }
    
    func startVoiceCapture() {
        selectedTab = .quickAdd
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay for view to appear
            await quickAddViewModel?.startRecording()
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView(
        speechService: SpeechService(),
        eventLogService: EventLogService(),
        notificationScheduler: NotificationScheduler(),
        syncService: SyncService(authService: AuthService())
    )
}

