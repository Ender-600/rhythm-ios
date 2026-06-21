//
//  SettingsView.swift
//  Rhythm
//
//  Settings view with notification preferences and data management
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("morningPreviewHour") private var morningPreviewHour = AppConfig.morningPreviewHour
    @AppStorage("morningPreviewMinute") private var morningPreviewMinute = AppConfig.morningPreviewMinute
    @AppStorage("notificationSoundsEnabled") private var notificationSoundsEnabled = true
    
    @State private var showingClearConfirmation = false
    
    @Bindable var authService: AuthService
    @Bindable var syncService: SyncService
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                List {
                    // Account
                    Section("Account") {
                        if authService.isAuthenticated {
                            HStack {
                                Label("Signed in", systemImage: "person.crop.circle.badge.checkmark")
                                Spacer()
                                Text(authService.userEmail ?? "Cloud account")
                                    .font(.caption)
                                    .foregroundColor(.rhythmTextSecondary)
                            }

                            Button {
                                Task {
                                    try? await authService.signOut()
                                    syncService.setCloudSyncEnabled(false)
                                }
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.rhythmError)
                            }
                        } else {
                            Text("Rhythm works locally on this device. Sign in only if you want cloud sync.")
                                .font(.subheadline)
                                .foregroundColor(.rhythmTextSecondary)

                            NavigationLink {
                                AuthView(authService: authService)
                            } label: {
                                Label("Sign In for Cloud Sync", systemImage: "person.crop.circle")
                            }
                        }
                    }

                    // Notifications
                    Section(Copy.Settings.notificationsSection) {
                        // Morning preview time
                        HStack {
                            Label(Copy.Settings.morningPreviewTime, systemImage: "sun.max")
                            Spacer()
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        var components = DateComponents()
                                        components.hour = morningPreviewHour
                                        components.minute = morningPreviewMinute
                                        return Calendar.current.date(from: components) ?? Date()
                                    },
                                    set: { newDate in
                                        let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                        morningPreviewHour = components.hour ?? 8
                                        morningPreviewMinute = components.minute ?? 0
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        
                        // Sounds toggle
                        Toggle(isOn: $notificationSoundsEnabled) {
                            Label(Copy.Settings.soundsEnabled, systemImage: "speaker.wave.2")
                        }
                    }
                    
                    // Data
                    Section(Copy.Settings.dataSection) {
                        Toggle(isOn: Binding(
                            get: { syncService.isCloudSyncEnabled },
                            set: { syncService.setCloudSyncEnabled($0) }
                        )) {
                            Label("Cloud Sync", systemImage: "icloud")
                        }
                        .disabled(!authService.isAuthenticated)

                        if !authService.isAuthenticated {
                            Text("Cloud sync requires sign in. Your local data stays available either way.")
                                .font(.caption)
                                .foregroundColor(.rhythmTextMuted)
                        }

                        // Sync status
                        HStack {
                            Label(Copy.Settings.syncStatus, systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if syncService.isCloudSyncEnabled {
                                SyncStatusBadge(
                                    isSyncing: syncService.isSyncing,
                                    pendingCount: syncService.pendingTaskCount + syncService.pendingEventCount,
                                    lastSyncTime: syncService.lastSyncTime
                                )
                            } else {
                                Text("Local only")
                                    .font(.caption)
                                    .foregroundColor(.rhythmTextMuted)
                            }
                        }
                        
                        Button {
                            Task {
                                await syncService.syncAll()
                            }
                        } label: {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(!authService.isAuthenticated || !syncService.isCloudSyncEnabled || syncService.isSyncing)

                        // Export data
                        Button {
                            // TODO: Implement data export
                        } label: {
                            Label(Copy.Settings.exportData, systemImage: "square.and.arrow.up")
                        }
                        
                        // Clear completed
                        Button {
                            showingClearConfirmation = true
                        } label: {
                            Label(Copy.Settings.clearCompleted, systemImage: "trash")
                                .foregroundColor(.rhythmError)
                        }
                    }
                    
                    // About
                    Section(Copy.Settings.aboutSection) {
                        // Version
                        HStack {
                            Label(Copy.Settings.version, systemImage: "info.circle")
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.rhythmTextSecondary)
                        }
                        
                        // Feedback
                        Button {
                            // TODO: Open feedback form or email
                        } label: {
                            Label(Copy.Settings.feedback, systemImage: "envelope")
                        }
                        
                        // Privacy
                        Button {
                            // TODO: Open privacy policy
                        } label: {
                            Label(Copy.Settings.privacy, systemImage: "hand.raised")
                        }
                    }
                    
                    // Debug (only in debug builds)
                    #if DEBUG
                    Section("Debug") {
                        Button {
                            // Reset onboarding, etc.
                        } label: {
                            Label("Reset App State", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button {
                            // Show pending notifications
                        } label: {
                            Label("View Pending Notifications", systemImage: "bell")
                        }
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Copy.Settings.title)
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear Completed Tasks?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    // TODO: Clear old completed tasks
                }
            } message: {
                Text("This will remove tasks completed more than 7 days ago. This cannot be undone.")
            }
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

#Preview {
    let auth = AuthService()
    SettingsView(
        authService: auth,
        syncService: SyncService(authService: auth)
    )
}
