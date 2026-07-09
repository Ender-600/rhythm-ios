//
//  SettingsView.swift
//  Rhythm
//
//  Settings view with notification preferences and data management
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("morningPreviewHour") private var morningPreviewHour = AppConfig.morningPreviewHour
    @AppStorage("morningPreviewMinute") private var morningPreviewMinute = AppConfig.morningPreviewMinute
    @AppStorage("notificationSoundsEnabled") private var notificationSoundsEnabled = true
    @AppStorage(CalendarService.addRhythmPlansToAppleCalendarKey) private var addRhythmPlansToAppleCalendar = false
    
    @State private var showingClearConfirmation = false
    @State private var isCalendarWorking = false
    @State private var calendarMessage: String?
    
    var syncService: SyncService?
    var calendarService: CalendarService?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    settingsHeader

                    List {
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

                        calendarSection
                    
                    // Data
                        Section(Copy.Settings.dataSection) {
                        // Sync status
                        HStack {
                            Label(Copy.Settings.syncStatus, systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if let sync = syncService {
                                SyncStatusBadge(
                                    isSyncing: sync.isSyncing,
                                    pendingCount: sync.pendingTaskCount + sync.pendingEventCount,
                                    lastSyncTime: sync.lastSyncTime
                                )
                            } else {
                                Text("Not configured")
                                    .font(.caption)
                                    .foregroundColor(.rhythmTextMuted)
                            }
                        }
                        
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
                    .listStyle(.plain)
                    .listRowSeparatorTint(Color.rhythmRule(for: colorScheme))
                    .tint(.rhythmSignal)
                    .environment(\.defaultMinListRowHeight, 48)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.rhythmBackground(for: colorScheme), for: .navigationBar)
            .alert("Clear Completed Tasks?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    // TODO: Clear old completed tasks
                }
            } message: {
                Text("This will remove tasks completed more than 7 days ago. This cannot be undone.")
            }
            .task {
                calendarService?.refreshAuthorizationStatus()
                calendarService?.refreshCalendarInfo()
            }
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETTINGS / SYSTEM")
                .swissSectionLabel(color: .rhythmSignal)

            Text(Copy.Settings.title)
                .font(.system(size: 36, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Color.rhythmTextPrimary)

            SwissRule(strong: true)
        }
        .padding(.horizontal, QuietSwiss.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private var calendarSection: some View {
        Section("Apple Calendar") {
            if let calendar = calendarService {
                HStack {
                    Label("Access", systemImage: "calendar.badge.checkmark")
                    Spacer()
                    Text(calendar.accessLevel.displayName)
                        .font(.caption)
                        .foregroundColor(.rhythmTextSecondary)
                }

                Button {
                    Task {
                        await requestCalendarAccess()
                    }
                } label: {
                    Label("Allow full Calendar access", systemImage: "lock.open")
                }
                .disabled(isCalendarWorking)

                Toggle(isOn: Binding(
                    get: { addRhythmPlansToAppleCalendar },
                    set: { enabled in
                        Task {
                            await setAppleCalendarSync(enabled)
                        }
                    }
                )) {
                    Label("Add Rhythm plans to Calendar", systemImage: "calendar.badge.plus")
                }
                .disabled(isCalendarWorking)

                Button {
                    Task {
                        await exportExistingPlans()
                    }
                } label: {
                    if isCalendarWorking {
                        Label("Syncing...", systemImage: "arrow.triangle.2.circlepath")
                    } else {
                        Label("Sync existing Rhythm plans", systemImage: "arrow.up.forward.app")
                    }
                }
                .disabled(!calendar.accessLevel.canWrite || isCalendarWorking)

                if calendar.accessLevel.canRead {
                    HStack {
                        Label("Calendars found", systemImage: "calendar")
                        Spacer()
                        Text("\(calendar.calendarCount)")
                            .foregroundColor(.rhythmTextSecondary)
                    }

                    ForEach(Array(calendar.upcomingEvents.prefix(3))) { event in
                        AppleCalendarEventRow(event: event)
                    }
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundColor(.rhythmTextSecondary)
                }

                if let error = calendar.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.rhythmError)
                }
            } else {
                Label("Calendar service is not configured", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.rhythmTextSecondary)
            }
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func requestCalendarAccess() async {
        guard let calendarService else { return }

        isCalendarWorking = true
        defer { isCalendarWorking = false }

        let granted = await calendarService.requestFullAccess()
        if granted {
            addRhythmPlansToAppleCalendar = true
            let result = exportPlannedTasksToCalendar()
            calendarMessage = calendarResultMessage(result, prefix: "Calendar access enabled.")
        } else {
            addRhythmPlansToAppleCalendar = false
            calendarMessage = calendarService.lastError ?? "Calendar access was not granted."
        }
    }

    private func setAppleCalendarSync(_ enabled: Bool) async {
        guard let calendarService else { return }

        isCalendarWorking = true
        defer { isCalendarWorking = false }

        guard enabled else {
            addRhythmPlansToAppleCalendar = false
            calendarMessage = "New Rhythm plans will stay inside Rhythm."
            return
        }

        if !calendarService.accessLevel.canWrite {
            let granted = await calendarService.requestFullAccess()
            guard granted else {
                addRhythmPlansToAppleCalendar = false
                calendarMessage = calendarService.lastError ?? "Calendar access was not granted."
                return
            }
        }

        addRhythmPlansToAppleCalendar = true
        let result = exportPlannedTasksToCalendar()
        calendarMessage = calendarResultMessage(result, prefix: "Calendar sync is on.")
    }

    private func exportExistingPlans() async {
        isCalendarWorking = true
        defer { isCalendarWorking = false }

        let result = exportPlannedTasksToCalendar()
        calendarMessage = calendarResultMessage(result, prefix: "Existing plans synced.")
    }

    private func exportPlannedTasksToCalendar() -> CalendarExportResult {
        guard let calendarService else { return CalendarExportResult() }

        let tasks = plannedTasksForCalendarExport()
        let result = calendarService.exportPlannedTasks(tasks)

        do {
            try modelContext.save()
        } catch {
            calendarMessage = "Calendar events were created, but Rhythm could not save their links."
        }

        calendarService.refreshCalendarInfo()
        return result
    }

    private func plannedTasksForCalendarExport() -> [RhythmTask] {
        let predicate = #Predicate<RhythmTask> { task in
            task.statusRaw != "done"
        }
        var descriptor = FetchDescriptor<RhythmTask>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.windowStart)]

        do {
            return try modelContext.fetch(descriptor).filter { $0.windowStart != nil }
        } catch {
            calendarMessage = "Could not load Rhythm plans for Calendar sync."
            return []
        }
    }

    private func calendarResultMessage(_ result: CalendarExportResult, prefix: String) -> String {
        "\(prefix) \(result.exported) added or updated, \(result.skipped) skipped, \(result.failed) failed."
    }
}

private struct AppleCalendarEventRow: View {
    let event: AppleCalendarEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "calendar")
                .foregroundColor(.rhythmCoral)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .foregroundColor(.rhythmTextPrimary)
                    .lineLimit(1)

                Text("\(event.startDate.shortTimeString) • \(event.calendarTitle)")
                    .font(.caption)
                    .foregroundColor(.rhythmTextSecondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(calendarService: CalendarService())
}
