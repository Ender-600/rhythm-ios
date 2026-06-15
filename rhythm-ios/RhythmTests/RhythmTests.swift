//
//  RhythmTests.swift
//  RhythmTests
//
//  Unit tests for core functionality
//

import Testing
import Foundation
@testable import Rhythm

// MARK: - Time Window Tests

@Suite("Time Window Tests")
struct TimeWindowTests {
    
    @Test("Snooze option calculates correct time - 10 minutes")
    func snoozeOption10Minutes() {
        let now = Date()
        let result = SnoozeOption.tenMinutes.calculateNewTime(from: now)
        
        #expect(result != nil)
        if let newTime = result {
            let diff = newTime.timeIntervalSince(now)
            #expect(abs(diff - 600) < 1) // 10 minutes = 600 seconds
        }
    }
    
    @Test("Snooze option calculates correct time - 30 minutes")
    func snoozeOption30Minutes() {
        let now = Date()
        let result = SnoozeOption.thirtyMinutes.calculateNewTime(from: now)
        
        #expect(result != nil)
        if let newTime = result {
            let diff = newTime.timeIntervalSince(now)
            #expect(abs(diff - 1800) < 1) // 30 minutes = 1800 seconds
        }
    }
    
    @Test("Snooze option calculates correct time - 1 hour")
    func snoozeOption1Hour() {
        let now = Date()
        let result = SnoozeOption.oneHour.calculateNewTime(from: now)
        
        #expect(result != nil)
        if let newTime = result {
            let diff = newTime.timeIntervalSince(now)
            #expect(abs(diff - 3600) < 1) // 1 hour = 3600 seconds
        }
    }
    
    @Test("Tomorrow snooze option sets 9 AM tomorrow")
    func snoozeTomorrow() {
        let now = Date()
        let result = SnoozeOption.tomorrow.calculateNewTime(from: now)
        
        #expect(result != nil)
        if let newTime = result {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .day], from: newTime)
            #expect(components.hour == 9)
            
            let nowDay = calendar.component(.day, from: now)
            let newDay = calendar.component(.day, from: newTime)
            // Could be next day or wrap to next month
            #expect(newDay != nowDay || calendar.component(.month, from: newTime) != calendar.component(.month, from: now))
        }
    }
    
    @Test("Custom snooze returns nil")
    func snoozeCustomReturnsNil() {
        let result = SnoozeOption.custom.calculateNewTime()
        #expect(result == nil)
    }
    
    @Test("Task is in window when time is between start and end")
    func taskIsInWindow() {
        let task = RhythmTask(
            title: "Test",
            windowStart: Date().addingTimeInterval(-3600), // 1 hour ago
            windowEnd: Date().addingTimeInterval(3600) // 1 hour from now
        )
        
        #expect(task.isInWindow == true)
    }
    
    @Test("Task is not in window when time has passed")
    func taskNotInWindowPassed() {
        let task = RhythmTask(
            title: "Test",
            windowStart: Date().addingTimeInterval(-7200), // 2 hours ago
            windowEnd: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        #expect(task.isInWindow == false)
    }
    
    @Test("Task is overdue when window end has passed")
    func taskIsOverdue() {
        let task = RhythmTask(
            title: "Test",
            windowStart: Date().addingTimeInterval(-7200),
            windowEnd: Date().addingTimeInterval(-3600)
        )
        
        #expect(task.isOverdue == true)
    }
    
    @Test("Completed task is not overdue")
    func completedTaskNotOverdue() {
        let task = RhythmTask(
            title: "Test",
            windowStart: Date().addingTimeInterval(-7200),
            windowEnd: Date().addingTimeInterval(-3600)
        )
        task.complete()
        
        #expect(task.isOverdue == false)
    }
    
    @Test("Window duration calculates correctly")
    func windowDurationCalculation() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour
        
        let task = RhythmTask(
            title: "Test",
            windowStart: start,
            windowEnd: end
        )
        
        #expect(task.windowDuration == 3600)
    }
}

// MARK: - Tag Normalization Tests

@Suite("Tag Normalization Tests")
struct TagNormalizationTests {
    
    @Test("Tag normalizes to lowercase")
    func tagNormalizesLowercase() {
        let normalized = Tag.normalize("WORK")
        #expect(normalized == "work")
    }
    
    @Test("Tag trims whitespace")
    func tagTrimsWhitespace() {
        let normalized = Tag.normalize("  email  ")
        #expect(normalized == "email")
    }
    
    @Test("Tag truncates to 20 characters")
    func tagTruncatesLength() {
        let longName = "this is a very long tag name that exceeds twenty characters"
        let normalized = Tag.normalize(longName)
        #expect(normalized.count == 20)
    }
    
    @Test("Tag equivalence check works")
    func tagEquivalenceCheck() {
        #expect(Tag.areEquivalent("Work", "work") == true)
        #expect(Tag.areEquivalent("  EMAIL  ", "email") == true)
        #expect(Tag.areEquivalent("work", "email") == false)
    }
    
    @Test("Tag display name includes hash")
    func tagDisplayNameIncludesHash() {
        let tag = Tag(name: "work")
        #expect(tag.displayName == "#work")
    }
}

// MARK: - Task Status Tests

@Suite("Task Status Tests")
struct TaskStatusTests {
    
    @Test("New task starts as not started")
    func newTaskStatus() {
        let task = RhythmTask(title: "Test")
        #expect(task.status == .notStarted)
    }
    
    @Test("Starting task changes status to in progress")
    func startTaskChangesStatus() {
        let task = RhythmTask(title: "Test")
        task.start()
        
        #expect(task.status == .inProgress)
        #expect(task.openedAt != nil)
    }
    
    @Test("Completing task changes status to done")
    func completeTaskChangesStatus() {
        let task = RhythmTask(title: "Test")
        task.start()
        task.complete()
        
        #expect(task.status == .done)
        #expect(task.completedAt != nil)
    }
    
    @Test("Skipping task sets skipped timestamp")
    func skipTaskSetsTimestamp() {
        let task = RhythmTask(title: "Test")
        task.skip()
        
        #expect(task.status == .done)
        #expect(task.skippedAt != nil)
    }
    
    @Test("Snoozing increments snooze count")
    func snoozeIncrementsCount() {
        let task = RhythmTask(title: "Test")
        let newTime = Date().addingTimeInterval(3600)
        
        task.snooze(to: newTime, option: .oneHour)
        #expect(task.snoozeCount == 1)
        
        task.snooze(to: newTime.addingTimeInterval(3600), option: .oneHour)
        #expect(task.snoozeCount == 2)
    }
    
    @Test("Snooze creates schedule change record")
    func snoozeCreatesScheduleChange() {
        let task = RhythmTask(
            title: "Test",
            windowStart: Date(),
            windowEnd: Date().addingTimeInterval(3600)
        )
        
        let newTime = Date().addingTimeInterval(7200)
        task.snooze(to: newTime, option: .oneHour, reason: "Need more time")
        
        #expect(task.scheduleChanges?.count == 1)
        #expect(task.scheduleChanges?.first?.changeType == .snoozed)
    }
}

// MARK: - Priority Tests

@Suite("Priority Tests")
struct PriorityTests {
    
    @Test("Default priority is normal")
    func defaultPriorityIsNormal() {
        let task = RhythmTask(title: "Test")
        #expect(task.priority == .normal)
    }
    
    @Test("Priority sort order is correct")
    func prioritySortOrder() {
        #expect(TaskPriority.must.sortOrder < TaskPriority.should.sortOrder)
        #expect(TaskPriority.should.sortOrder < TaskPriority.could.sortOrder)
    }
    
    @Test("Priority has display name")
    func priorityDisplayName() {
        #expect(TaskPriority.must.displayName == "Must do")
        #expect(TaskPriority.should.displayName == "Should do")
        #expect(TaskPriority.could.displayName == "Could do")
    }
}

// MARK: - Date Extension Tests

@Suite("Date Extension Tests")
struct DateExtensionTests {
    
    @Test("Time interval formats as duration")
    func timeIntervalDuration() {
        let oneHour: TimeInterval = 3600
        #expect(oneHour.durationString == "1h")
        
        let ninetyMinutes: TimeInterval = 5400
        #expect(ninetyMinutes.durationString == "1h 30m")
        
        let thirtyMinutes: TimeInterval = 1800
        #expect(thirtyMinutes.durationString == "30m")
    }
    
    @Test("Short duration string formats correctly")
    func shortDurationFormat() {
        let twoMinutes: TimeInterval = 125
        #expect(twoMinutes.shortDurationString == "2:05")
    }
    
    @Test("Adding hours works correctly")
    func addingHours() {
        let now = Date()
        let later = now.adding(hours: 2)
        
        let diff = later.timeIntervalSince(now)
        #expect(abs(diff - 7200) < 1)
    }
    
    @Test("Adding minutes works correctly")
    func addingMinutes() {
        let now = Date()
        let later = now.adding(minutes: 30)
        
        let diff = later.timeIntervalSince(now)
        #expect(abs(diff - 1800) < 1)
    }
}

// MARK: - Plan Signal Tests

@Suite("Plan Signal Tests")
struct PlanSignalTests {
    
    @Test("Signal type affects schedule flag")
    func signalTypeAffectsSchedule() {
        let timeSignal = PlanSignal(rawText: "tonight", signalType: .timeRelative)
        #expect(timeSignal.affectsSchedule == true)
        
        let prioritySignal = PlanSignal(rawText: "important", signalType: .priority)
        #expect(prioritySignal.affectsSchedule == false)
    }
    
    @Test("Confidence is clamped to 0-1")
    func confidenceClamped() {
        let highConfidence = PlanSignal(rawText: "test", signalType: .unknown, confidence: 1.5)
        #expect(highConfidence.confidence == 1.0)
        
        let lowConfidence = PlanSignal(rawText: "test", signalType: .unknown, confidence: -0.5)
        #expect(lowConfidence.confidence == 0.0)
    }
}

// MARK: - Event Log Tests

@Suite("Event Log Tests")
struct EventLogTests {
    
    @Test("Event log captures metadata")
    func eventLogCapturesMetadata() {
        let event = EventLog(
            eventType: .taskCreated,
            metadata: ["key": "value", "count": 42]
        )
        
        let decoded = event.decodedMetadata()
        #expect(decoded?["key"] as? String == "value")
        #expect(decoded?["count"] as? Int == 42)
    }
    
    @Test("Factory method creates task event")
    func factoryCreatesTaskEvent() {
        let taskId = UUID()
        let event = EventLog.taskEvent(.taskStarted, taskId: taskId)
        
        #expect(event.eventType == "task_started")
        #expect(event.taskId == taskId)
    }
}
