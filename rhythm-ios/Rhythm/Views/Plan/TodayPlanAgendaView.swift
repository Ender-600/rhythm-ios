//
//  TodayPlanAgendaView.swift
//  Rhythm
//
//  Editorial day plan: current focus, today's agenda, and the largest open block.
//

import SwiftUI

struct TodayPlanAgendaView: View {
    let date: Date
    let tasks: [RhythmTask]
    var onTaskTap: ((RhythmTask) -> Void)?
    var onSnooze: ((RhythmTask) -> Void)?
    var onStart: ((RhythmTask) -> Void)?
    var onCreateSelection: ((PlanTimeSelection) -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    dayHeader(at: context.date)

                    if let featuredTask = featuredTask(at: context.date) {
                        currentFocus(featuredTask, at: context.date)
                    } else {
                        openDayFocus(at: context.date)
                    }

                    agenda(at: context.date)

                    if let openSlot = largestOpenSlot(at: context.date) {
                        openTime(openSlot)
                    }
                }
                .padding(.horizontal, QuietSwiss.screenPadding)
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
        }
    }

    private func dayHeader(at now: Date) -> some View {
        HStack(alignment: .top) {
            Text("RHYTHM")
                .font(.caption.weight(.black))
                .tracking(2.4)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(dayLabel)
                    .font(.caption.weight(.black))

                Text("\(locationLabel)  ·  \(clockString(for: now))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(Color.rhythmTextMuted)
            }
        }
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            SwissRule(strong: true)
        }
    }

    private func currentFocus(_ task: RhythmTask, at now: Date) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 10) {
                Text(hourString(for: displayTime(for: task, at: now)))
                    .font(.system(size: 78, weight: .bold))
                    .tracking(-5)

                Text(minuteString(for: displayTime(for: task, at: now)))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .padding(.top, 10)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(focusStatus(for: task, at: now))
                        .font(.caption2.weight(.black))
                        .tracking(1.5)
                        .foregroundStyle(Color.rhythmSignal)

                    Text(focusTiming(for: task, at: now))
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color.rhythmTextPrimary)
                }
                .padding(.top, 13)
            }

            Button {
                onTaskTap?(task)
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor(for: task))
                        .frame(width: 7, height: 82)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(task.title.uppercased())
                            .font(.title3.weight(.black))
                            .tracking(-0.4)
                            .foregroundStyle(Color.rhythmTextPrimary)
                            .multilineTextAlignment(.leading)

                        Text(task.openingAction ?? task.notes ?? "A focused block for this part of the day.")
                            .font(.subheadline)
                            .foregroundStyle(Color.rhythmTextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button(task.status == .inProgress ? "CONTINUE" : "BEGIN") {
                    onStart?(task)
                }
                .buttonStyle(DayPlanActionStyle(prominent: true))

                Button("MOVE LATER") {
                    onSnooze?(task)
                }
                .buttonStyle(DayPlanActionStyle(prominent: false))
            }
        }
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            SwissRule()
        }
    }

    private func openDayFocus(at now: Date) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 10) {
                Text(hourString(for: now))
                    .font(.system(size: 78, weight: .bold))
                    .tracking(-5)

                Text(minuteString(for: now))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .padding(.top, 10)

                Spacer()

                Text("OPEN")
                    .font(.caption2.weight(.black))
                    .tracking(1.5)
                    .foregroundStyle(Color.rhythmSignal)
                    .padding(.top, 13)
            }

            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.rhythmGreen)
                    .frame(width: 7, height: 70)

                VStack(alignment: .leading, spacing: 7) {
                    Text("KEEP THE DAY OPEN")
                        .font(.title3.weight(.black))
                    Text("Nothing is asking for this time yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.rhythmTextSecondary)
                }
            }
        }
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            SwissRule()
        }
    }

    private func agenda(at now: Date) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(Calendar.current.isDateInToday(date) ? "TODAY" : "DAY") / \(String(format: "%02d", tasks.count))")
                    .font(.caption2.weight(.black))
                    .tracking(1.6)

                Spacer()

                Text("LOCAL TIME")
                    .font(.caption2.monospaced())
                    .foregroundStyle(Color.rhythmTextMuted)
            }
            .padding(.vertical, 13)

            ForEach(Array(agendaTasks(at: now).enumerated()), id: \.element.id) { index, task in
                Button {
                    onTaskTap?(task)
                } label: {
                    DayPlanAgendaRow(
                        index: index + 1,
                        task: task,
                        accent: accentColor(for: task)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openTime(_ selection: PlanTimeSelection) -> some View {
        Button {
            onCreateSelection?(selection)
        } label: {
            HStack(alignment: .top) {
                Text(timeRangeString(from: selection.start, to: selection.end))
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.rhythmTextPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("UNPLANNED")
                        .font(.caption2.weight(.black))
                        .tracking(1.4)
                        .foregroundStyle(Color.rhythmTextPrimary)

                    Text("Keep it open")
                        .font(.caption)
                        .foregroundStyle(Color.rhythmTextMuted)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                SwissRule()
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Creates a plan in this open time")
    }

    private func featuredTask(at now: Date) -> RhythmTask? {
        if Calendar.current.isDateInToday(date) {
            if let inProgress = tasks.first(where: { $0.status == .inProgress }) {
                return inProgress
            }

            if let current = tasks.first(where: { $0.isInWindow }) {
                return current
            }

            if let next = tasks.first(where: { ($0.windowStart ?? .distantPast) > now }) {
                return next
            }
        }

        return tasks.first
    }

    private func agendaTasks(at now: Date) -> [RhythmTask] {
        guard let featuredTask = featuredTask(at: now) else { return tasks }
        return tasks.filter { $0.id != featuredTask.id }
    }

    private func displayTime(for task: RhythmTask, at now: Date) -> Date {
        Calendar.current.isDateInToday(date) ? now : task.windowStart ?? date
    }

    private func focusStatus(for task: RhythmTask, at now: Date) -> String {
        if task.status == .inProgress || task.isInWindow {
            return "NOW"
        }

        if let start = task.windowStart, start > now {
            return "NEXT"
        }

        return "FOCUS"
    }

    private func focusTiming(for task: RhythmTask, at now: Date) -> String {
        if let end = task.windowEnd, end > now, task.status == .inProgress || task.isInWindow {
            let minutes = max(1, Int(ceil(end.timeIntervalSince(now) / 60)))
            return "\(minutes) MIN LEFT"
        }

        if let start = task.windowStart, start > now, Calendar.current.isDateInToday(date) {
            let minutes = max(1, Int(ceil(start.timeIntervalSince(now) / 60)))
            return "IN \(minutes) MIN"
        }

        if let start = task.windowStart {
            return clockString(for: start)
        }

        return "FLEXIBLE"
    }

    private func largestOpenSlot(at now: Date) -> PlanTimeSelection? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let planningStart = dayStart.adding(hours: 8)
        let planningEnd = dayStart.adding(hours: 21)
        let lowerBound = calendar.isDateInToday(date)
            ? max(planningStart, roundedUpToQuarterHour(now))
            : planningStart

        guard lowerBound < planningEnd else { return nil }

        let intervals = tasks.compactMap { task -> (Date, Date)? in
            guard let start = task.windowStart else { return nil }
            let fallbackMinutes = task.estimatedMinutes ?? 30
            let end = task.windowEnd ?? start.adding(minutes: fallbackMinutes)
            guard end > lowerBound, start < planningEnd else { return nil }
            return (max(start, lowerBound), min(end, planningEnd))
        }
        .sorted { $0.0 < $1.0 }

        var cursor = lowerBound
        var gaps: [PlanTimeSelection] = []

        for interval in intervals {
            if interval.0.timeIntervalSince(cursor) >= 30 * 60 {
                gaps.append(PlanTimeSelection(start: cursor, end: interval.0))
            }
            cursor = max(cursor, interval.1)
        }

        if planningEnd.timeIntervalSince(cursor) >= 30 * 60 {
            gaps.append(PlanTimeSelection(start: cursor, end: planningEnd))
        }

        return gaps.max { $0.durationMinutes < $1.durationMinutes }
    }

    private func roundedUpToQuarterHour(_ date: Date) -> Date {
        let interval: TimeInterval = 15 * 60
        return Date(timeIntervalSince1970: ceil(date.timeIntervalSince1970 / interval) * interval)
    }

    private func accentColor(for task: RhythmTask) -> Color {
        switch task.priority {
        case .urgent: return .rhythmSignal
        case .normal: return .rhythmGreen
        case .low: return .rhythmOchre
        }
    }

    private var locationLabel: String {
        let city = TimeZone.current.identifier
            .split(separator: "/")
            .last
            .map(String.init) ?? "Local"

        return city
            .replacingOccurrences(of: "_", with: " ")
            .uppercased()
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE dd MMM"
        return formatter.string(from: date).uppercased()
    }

    private func clockString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func timeRangeString(from start: Date, to end: Date) -> String {
        "\(clockString(for: start))—\(clockString(for: end))"
    }

    private func hourString(for date: Date) -> String {
        String(format: "%02d", Calendar.current.component(.hour, from: date))
    }

    private func minuteString(for date: Date) -> String {
        String(format: "%02d", Calendar.current.component(.minute, from: date))
    }
}

private struct DayPlanAgendaRow: View {
    let index: Int
    let task: RhythmTask
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(indexLabel)
                .font(.caption2.monospaced())
                .foregroundStyle(Color.rhythmTextMuted)
                .frame(width: 22)

            RoundedRectangle(cornerRadius: 3)
                .fill(accent)
                .frame(width: 5, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.windowStart.map(clockString) ?? "Flexible")
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.rhythmTextPrimary)

                Text(task.title.uppercased())
                    .font(.subheadline.weight(.bold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.rhythmTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Text(durationLabel)
                .font(.caption2.monospaced())
                .foregroundStyle(Color.rhythmTextMuted)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .top) {
            SwissRule()
        }
    }

    private var indexLabel: String {
        String(format: "%02d", index)
    }

    private var durationLabel: String {
        if let duration = task.windowDuration {
            return "\(max(1, Int(duration / 60))) MIN"
        }

        if let estimate = task.estimatedMinutes {
            return "\(estimate) MIN"
        }

        return "FLEX"
    }

    private func clockString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct DayPlanActionStyle: ButtonStyle {
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption2.weight(.black))
            .tracking(1.1)
            .foregroundStyle(prominent ? Color.rhythmPaper : Color.rhythmTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(prominent ? Color.rhythmInk : Color.rhythmCardLight)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.rhythmRuleLight, lineWidth: prominent ? 0 : 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

#Preview {
    let now = Date()
    TodayPlanAgendaView(
        date: now,
        tasks: [
            RhythmTask(
                title: "Prepare project notes",
                windowStart: now.adding(minutes: -10),
                windowEnd: now.adding(minutes: 48),
                priority: .urgent,
                openingAction: "Start with the open questions from yesterday."
            ),
            RhythmTask(
                title: "Walk outside",
                windowStart: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: now),
                windowEnd: Calendar.current.date(bySettingHour: 13, minute: 30, second: 0, of: now),
                priority: .normal
            ),
            RhythmTask(
                title: "Review tomorrow",
                windowStart: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: now),
                windowEnd: Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: now),
                priority: .urgent
            )
        ]
    )
}
