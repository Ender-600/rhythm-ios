//
//  CalendarService.swift
//  Rhythm
//
//  Bridges Rhythm plans with the user's Apple Calendar.
//

import EventKit
import Foundation

struct AppleCalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
}

struct CalendarExportResult: Equatable {
    var exported: Int = 0
    var skipped: Int = 0
    var failed: Int = 0
}

@Observable
@MainActor
final class CalendarService {
    static let addRhythmPlansToAppleCalendarKey = "addRhythmPlansToAppleCalendar"

    enum AccessLevel: String {
        case notDetermined
        case fullAccess
        case writeOnly
        case denied
        case restricted
        case unknown

        var canRead: Bool {
            self == .fullAccess
        }

        var canWrite: Bool {
            self == .fullAccess || self == .writeOnly
        }

        var displayName: String {
            switch self {
            case .notDetermined: return "Not requested"
            case .fullAccess: return "Full access"
            case .writeOnly: return "Write only"
            case .denied: return "Denied"
            case .restricted: return "Restricted"
            case .unknown: return "Unknown"
            }
        }
    }

    enum CalendarError: LocalizedError {
        case readAccessRequired
        case writeAccessRequired
        case missingTimeWindow
        case noWritableCalendar

        var errorDescription: String? {
            switch self {
            case .readAccessRequired:
                return "Calendar read access is required."
            case .writeAccessRequired:
                return "Calendar write access is required."
            case .missingTimeWindow:
                return "This plan does not have a scheduled time window."
            case .noWritableCalendar:
                return "No writable Apple Calendar is available."
            }
        }
    }

    private let eventStore = EKEventStore()

    private(set) var accessLevel: AccessLevel = .notDetermined
    private(set) var calendarCount = 0
    private(set) var upcomingEvents: [AppleCalendarEvent] = []
    private(set) var lastError: String?

    init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .notDetermined:
            accessLevel = .notDetermined
        case .restricted:
            accessLevel = .restricted
        case .denied:
            accessLevel = .denied
        case .authorized:
            accessLevel = .fullAccess
        case .fullAccess:
            accessLevel = .fullAccess
        case .writeOnly:
            accessLevel = .writeOnly
        @unknown default:
            accessLevel = .unknown
        }
    }

    @discardableResult
    func requestFullAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            refreshAuthorizationStatus()

            if granted {
                refreshCalendarInfo()
            }

            lastError = granted ? nil : "Calendar access was not granted."
            return granted
        } catch {
            refreshAuthorizationStatus()
            lastError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func requestWriteOnlyAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestWriteOnlyAccessToEvents()
            refreshAuthorizationStatus()
            lastError = granted ? nil : "Calendar write access was not granted."
            return granted
        } catch {
            refreshAuthorizationStatus()
            lastError = error.localizedDescription
            return false
        }
    }

    func refreshCalendarInfo(daysAhead: Int = 7) {
        refreshAuthorizationStatus()

        guard accessLevel.canRead else {
            calendarCount = 0
            upcomingEvents = []
            return
        }

        let calendars = eventStore.calendars(for: .event)
        calendarCount = calendars.count

        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: daysAhead, to: start) ?? start.addingTimeInterval(7 * 24 * 60 * 60)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)

        upcomingEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .prefix(20)
            .map { event in
                AppleCalendarEvent(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    calendarTitle: event.calendar.title
                )
            }
    }

    func upsertCalendarEvent(for task: RhythmTask) throws {
        refreshAuthorizationStatus()

        guard accessLevel.canWrite else {
            throw CalendarError.writeAccessRequired
        }
        guard let start = task.windowStart else {
            throw CalendarError.missingTimeWindow
        }

        let end = task.windowEnd
            ?? task.deadline
            ?? start.addingTimeInterval(TimeInterval((task.estimatedMinutes ?? 30) * 60))

        let event: EKEvent
        if let existingId = task.appleCalendarEventIdentifier,
           let existingEvent = eventStore.event(withIdentifier: existingId) {
            event = existingEvent
        } else {
            event = EKEvent(eventStore: eventStore)
            event.calendar = defaultWritableCalendar()
        }

        guard event.calendar != nil else {
            throw CalendarError.noWritableCalendar
        }

        event.title = task.title
        event.startDate = start
        event.endDate = max(end, start.addingTimeInterval(15 * 60))
        event.notes = calendarNotes(for: task)

        try eventStore.save(event, span: .thisEvent, commit: true)

        task.appleCalendarEventIdentifier = event.eventIdentifier
        task.appleCalendarSyncedAt = Date()
        task.markDirty()
    }

    func exportPlannedTasks(_ tasks: [RhythmTask]) -> CalendarExportResult {
        var result = CalendarExportResult()

        for task in tasks {
            guard task.windowStart != nil, task.status != .done else {
                result.skipped += 1
                continue
            }

            do {
                try upsertCalendarEvent(for: task)
                result.exported += 1
            } catch {
                result.failed += 1
                lastError = error.localizedDescription
            }
        }

        return result
    }

    private func defaultWritableCalendar() -> EKCalendar? {
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
           defaultCalendar.allowsContentModifications {
            return defaultCalendar
        }

        return eventStore.calendars(for: .event).first { $0.allowsContentModifications }
    }

    private func calendarNotes(for task: RhythmTask) -> String {
        var parts = ["Created by Rhythm."]

        if let openingAction = task.openingAction {
            parts.append("First step: \(openingAction)")
        }
        if let notes = task.notes {
            parts.append(notes)
        }

        return parts.joined(separator: "\n\n")
    }
}
