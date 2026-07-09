//
//  DesignLabNewDirections.swift
//  Rhythm
//
//  Three non-AI-coded visual directions: Swiss utility, seasonal almanac,
//  and tactile instrument design.
//

import SwiftUI

// MARK: - Direction 4: Quiet Swiss

struct QuietSwissDemo: View {
    private let paper = Color(red: 0.965, green: 0.96, blue: 0.925)
    private let ink = Color(red: 0.06, green: 0.06, blue: 0.055)
    private let signal = Color(red: 0.80, green: 0.15, blue: 0.08)
    private let rule = Color.black.opacity(0.18)

    var body: some View {
        ZStack(alignment: .bottom) {
            paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    swissHeader
                    currentTimeBlock
                    agenda
                    openTime
                    Color.clear.frame(height: 84)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }

            SwissBottomBar(signal: signal, paper: paper, ink: ink)
        }
        .foregroundStyle(ink)
    }

    private var swissHeader: some View {
        HStack(alignment: .top) {
            Text("RHYTHM")
                .font(.caption.weight(.black))
                .tracking(2.4)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("THU 09 JUL")
                    .font(.caption.weight(.bold))
                Text("SHANGHAI · 09:42")
                    .font(.caption2.monospaced())
                    .foregroundStyle(ink.opacity(0.48))
            }
        }
        .padding(.bottom, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(ink).frame(height: 2)
        }
    }

    private var currentTimeBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text("09")
                    .font(.system(size: 76, weight: .bold, design: .default))
                    .tracking(-5)

                Text("42")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .padding(.top, 10)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("NOW")
                        .font(.caption2.weight(.black))
                        .tracking(1.5)
                        .foregroundStyle(signal)
                    Text("48 MIN LEFT")
                        .font(.caption2.monospaced())
                }
                .padding(.top, 12)
            }

            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(signal)
                    .frame(width: 7, height: 74)

                VStack(alignment: .leading, spacing: 7) {
                    Text("PREPARE PROJECT NOTES")
                        .font(.title3.weight(.black))
                        .tracking(-0.4)

                    Text("Start with the open questions from yesterday.")
                        .font(.subheadline)
                        .foregroundStyle(ink.opacity(0.58))
                }

                Spacer()
            }

            HStack(spacing: 0) {
                Button("BEGIN") {}
                    .buttonStyle(SwissActionStyle(filled: true, ink: ink, paper: paper))
                Button("MOVE LATER") {}
                    .buttonStyle(SwissActionStyle(filled: false, ink: ink, paper: paper))
            }
        }
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Rectangle().fill(ink).frame(height: 1)
        }
    }

    private var agenda: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TODAY / 03")
                    .font(.caption2.weight(.black))
                    .tracking(1.6)
                Spacer()
                Text("LOCAL TIME")
                    .font(.caption2.monospaced())
                    .foregroundStyle(ink.opacity(0.45))
            }
            .padding(.vertical, 12)

            SwissAgendaRow(
                index: "01",
                time: "13:00",
                title: "WALK OUTSIDE",
                duration: "30 MIN",
                color: Color(red: 0.18, green: 0.38, blue: 0.28),
                rule: rule
            )

            SwissAgendaRow(
                index: "02",
                time: "18:00",
                title: "REVIEW TOMORROW",
                duration: "30 MIN",
                color: signal,
                rule: rule
            )
        }
    }

    private var openTime: some View {
        HStack(alignment: .top) {
            Text("14:00—17:30")
                .font(.caption.monospaced())

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("UNPLANNED")
                    .font(.caption2.weight(.black))
                    .tracking(1.4)
                Text("Keep it open")
                    .font(.caption)
                    .foregroundStyle(ink.opacity(0.48))
            }
        }
        .padding(.vertical, 15)
        .overlay(alignment: .top) {
            Rectangle().fill(rule).frame(height: 1)
        }
    }
}

private struct SwissActionStyle: ButtonStyle {
    let filled: Bool
    let ink: Color
    let paper: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption2.weight(.black))
            .tracking(1.1)
            .foregroundStyle(filled ? paper : ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(filled ? ink : Color.clear)
            .overlay {
                Rectangle().stroke(ink, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

private struct SwissAgendaRow: View {
    let index: String
    let time: String
    let title: String
    let duration: String
    let color: Color
    let rule: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(index)
                .font(.caption2.monospaced())
                .foregroundStyle(Color.primary.opacity(0.42))
                .frame(width: 20)

            Rectangle()
                .fill(color)
                .frame(width: 5, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(time)
                    .font(.caption.monospaced())
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .tracking(-0.2)
            }

            Spacer()

            Text(duration)
                .font(.caption2.monospaced())
                .foregroundStyle(Color.primary.opacity(0.45))
        }
        .padding(.vertical, 13)
        .overlay(alignment: .top) {
            Rectangle().fill(rule).frame(height: 1)
        }
    }
}

private struct SwissBottomBar: View {
    let signal: Color
    let paper: Color
    let ink: Color

    var body: some View {
        HStack(spacing: 0) {
            SwissTabItem(title: "PLAN", icon: "calendar", selected: true, ink: ink, signal: signal)
            SwissTabItem(title: "TASKS", icon: "checklist", selected: false, ink: ink, signal: signal)

            Image(systemName: "mic.fill")
                .font(.body.weight(.bold))
                .foregroundStyle(paper)
                .frame(width: 52, height: 52)
                .background(signal)

            SwissTabItem(title: "MEMORY", icon: "circle.grid.2x2", selected: false, ink: ink, signal: signal)
            SwissTabItem(title: "SETTINGS", icon: "gearshape", selected: false, ink: ink, signal: signal)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .background(paper)
        .overlay(alignment: .top) {
            Rectangle().fill(ink).frame(height: 2)
        }
    }
}

private struct SwissTabItem: View {
    let title: String
    let icon: String
    let selected: Bool
    let ink: Color
    let signal: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.system(size: 7, weight: .black))
                .tracking(0.4)
        }
        .foregroundStyle(selected ? signal : ink.opacity(0.48))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Direction 5: Seasonal Almanac

struct SeasonalAlmanacDemo: View {
    private let ricePaper = Color(red: 0.95, green: 0.91, blue: 0.82)
    private let ink = Color(red: 0.18, green: 0.18, blue: 0.14)
    private let moss = Color(red: 0.39, green: 0.45, blue: 0.27)
    private let persimmon = Color(red: 0.72, green: 0.29, blue: 0.16)
    private let indigo = Color(red: 0.22, green: 0.28, blue: 0.34)

    var body: some View {
        ZStack(alignment: .bottom) {
            ricePaper.ignoresSafeArea()
            paperTexture

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    almanacHeader
                    morningNote
                    dayEntries
                    breathingRoom
                    Color.clear.frame(height: 86)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
            }

            AlmanacBottomBar(paper: ricePaper, ink: ink, moss: moss)
        }
        .foregroundStyle(ink)
    }

    private var paperTexture: some View {
        Canvas { context, size in
            for index in 0..<18 {
                let y = CGFloat(index) * max(size.height / 17, 1)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y + 3))
                context.stroke(path, with: .color(ink.opacity(0.018)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }

    private var almanacHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Text("09")
                    .font(.system(size: 54, weight: .medium, design: .serif))
                Text("JUL")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
            }
            .frame(width: 76)
            .padding(.vertical, 9)
            .overlay {
                RoundedRectangle(cornerRadius: 38)
                    .stroke(ink.opacity(0.45), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Thursday")
                    .font(.system(size: 28, weight: .medium, design: .serif))

                Text("Minor Heat · day three")
                    .font(.caption)
                    .foregroundStyle(persimmon)

                Text("Warm air, a slower afternoon.")
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.55))
            }
            .padding(.top, 7)

            Spacer()
        }
        .padding(.bottom, 21)
    }

    private var morningNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sun.haze")
                    .foregroundStyle(persimmon)
                Text("A note for today")
                    .font(.caption.weight(.semibold))
                    .tracking(0.6)
            }

            Text("Three things have found their place.\nLet the afternoon stay spacious.")
                .font(.system(size: 22, weight: .regular, design: .serif))
                .lineSpacing(5)
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            Rectangle().fill(ink.opacity(0.32)).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(ink.opacity(0.12)).frame(height: 1)
        }
    }

    private var dayEntries: some View {
        VStack(spacing: 0) {
            AlmanacEntry(
                time: "09:30",
                title: "Prepare project notes",
                note: "Begin with one open question",
                symbol: "pencil.line",
                tint: indigo,
                isCurrent: true
            )

            AlmanacEntry(
                time: "13:00",
                title: "Walk outside",
                note: "Thirty minutes beneath the trees",
                symbol: "leaf",
                tint: moss,
                isCurrent: false
            )

            AlmanacEntry(
                time: "18:00",
                title: "Review tomorrow",
                note: "Close the day without rushing",
                symbol: "moon.stars",
                tint: persimmon,
                isCurrent: false
            )
        }
        .padding(.top, 8)
    }

    private var breathingRoom: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack {
                Circle()
                    .fill(moss.opacity(0.15))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "wind")
                            .font(.caption)
                            .foregroundStyle(moss)
                    }
                Rectangle()
                    .fill(moss.opacity(0.22))
                    .frame(width: 1, height: 46)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("14:00—17:30")
                    .font(.caption.monospaced())
                    .foregroundStyle(moss)

                Text("Unwritten time")
                    .font(.system(size: 19, weight: .medium, design: .serif))

                Text("Nothing needs to fill this space.")
                    .font(.caption)
                    .foregroundStyle(ink.opacity(0.5))
            }
            .padding(.top, 3)
        }
        .padding(.top, 6)
    }
}

private struct AlmanacEntry: View {
    let time: String
    let title: String
    let note: String
    let symbol: String
    let tint: Color
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(time)
                .font(.caption.monospaced())
                .foregroundStyle(Color.primary.opacity(0.5))
                .frame(width: 44, alignment: .leading)

            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.12), in: Circle())

                Rectangle()
                    .fill(tint.opacity(0.22))
                    .frame(width: 1, height: 30)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .medium, design: .serif))

                    if isCurrent {
                        Text("NOW")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(tint)
                    }
                }

                Text(note)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.48))
            }
            .padding(.top, 3)

            Spacer()
        }
        .padding(.vertical, 10)
    }
}

private struct AlmanacBottomBar: View {
    let paper: Color
    let ink: Color
    let moss: Color

    var body: some View {
        HStack {
            AlmanacTab(title: "Today", symbol: "sun.max", selected: true, ink: ink, moss: moss)
            AlmanacTab(title: "Tasks", symbol: "checkmark", selected: false, ink: ink, moss: moss)

            Image(systemName: "mic")
                .font(.body.weight(.medium))
                .foregroundStyle(paper)
                .frame(width: 50, height: 50)
                .background(moss, in: Circle())
                .overlay {
                    Circle().stroke(paper.opacity(0.8), lineWidth: 4)
                }

            AlmanacTab(title: "Memory", symbol: "book.closed", selected: false, ink: ink, moss: moss)
            AlmanacTab(title: "More", symbol: "ellipsis", selected: false, ink: ink, moss: moss)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(paper.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle().fill(ink.opacity(0.18)).frame(height: 1)
        }
    }
}

private struct AlmanacTab: View {
    let title: String
    let symbol: String
    let selected: Bool
    let ink: Color
    let moss: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.caption)
            Text(title)
                .font(.system(size: 9, design: .serif))
        }
        .foregroundStyle(selected ? moss : ink.opacity(0.45))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Direction 6: Tactile Instrument

struct TactileInstrumentDemo: View {
    @Binding var isRecording: Bool

    private let chassis = Color(red: 0.76, green: 0.74, blue: 0.68)
    private let panel = Color(red: 0.85, green: 0.83, blue: 0.76)
    private let dark = Color(red: 0.10, green: 0.10, blue: 0.09)
    private let orange = Color(red: 0.92, green: 0.27, blue: 0.09)
    private let green = Color(red: 0.23, green: 0.43, blue: 0.29)

    var body: some View {
        ZStack(alignment: .bottom) {
            chassis.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    instrumentHeader
                    statusDisplay
                    controlPanel
                    taskChannels
                    Color.clear.frame(height: 82)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            InstrumentBottomBar(chassis: chassis, dark: dark, orange: orange)
        }
        .foregroundStyle(dark)
    }

    private var instrumentHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("RHYTHM")
                    .font(.headline.weight(.black))
                    .tracking(2)
                Text("DAY CONTROL / R-09")
                    .font(.caption2.monospaced())
                    .foregroundStyle(dark.opacity(0.55))
            }

            Spacer()

            HStack(spacing: 8) {
                StatusLamp(color: green, label: "PLAN")
                StatusLamp(color: orange, label: "LIVE")
            }
        }
        .padding(.horizontal, 2)
    }

    private var statusDisplay: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CURRENT WINDOW")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.2)
                        .foregroundStyle(Color.white.opacity(0.5))
                    Text("09:30—10:30")
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(Color(red: 0.91, green: 0.76, blue: 0.38))
                }

                Spacer()

                Text("00:48")
                    .font(.title2.monospacedDigit().weight(.medium))
                    .foregroundStyle(Color(red: 0.60, green: 0.83, blue: 0.59))
            }
            .padding(15)

            HStack {
                Text("PREPARE PROJECT NOTES")
                    .font(.caption.weight(.black))
                    .tracking(0.6)
                Spacer()
                Text("CH 01")
                    .font(.caption2.monospaced())
            }
            .foregroundStyle(Color.white.opacity(0.82))
            .padding(.horizontal, 15)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.06))
        }
        .background(dark, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: dark.opacity(0.22), radius: 3, y: 2)
    }

    private var controlPanel: some View {
        HStack(spacing: 18) {
            Button {
                isRecording.toggle()
            } label: {
                TactileKnob(isActive: isRecording, dark: dark, orange: orange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRecording ? "Stop voice input" : "Start voice input")

            VStack(alignment: .leading, spacing: 9) {
                Text(isRecording ? "VOICE INPUT ACTIVE" : "VOICE INPUT")
                    .font(.caption2.weight(.black))
                    .tracking(1.2)

                Text(isRecording ? "Listening…" : "Press the dial")
                    .font(.title3.weight(.bold))

                HStack(spacing: 4) {
                    ForEach(0..<12, id: \.self) { index in
                        Capsule()
                            .fill(isRecording && index < 8 ? orange : dark.opacity(0.16))
                            .frame(width: 4, height: CGFloat(7 + (index % 4) * 3))
                    }
                }
                .frame(height: 18, alignment: .bottom)

                Text("TAP TO \(isRecording ? "STOP" : "RECORD")")
                    .font(.caption2.monospaced())
                    .foregroundStyle(dark.opacity(0.5))
            }

            Spacer()
        }
        .padding(16)
        .background(panel, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(dark.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: dark.opacity(0.16), radius: 3, y: 2)
    }

    private var taskChannels: some View {
        VStack(spacing: 9) {
            HStack {
                Text("SCHEDULED CHANNELS")
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                Spacer()
                Text("3 ACTIVE")
                    .font(.caption2.monospaced())
            }
            .padding(.horizontal, 2)

            InstrumentTaskChannel(
                channel: "02",
                time: "13:00",
                title: "WALK OUTSIDE",
                detail: "30 MIN / FLEX",
                lamp: green,
                panel: panel,
                dark: dark
            )

            InstrumentTaskChannel(
                channel: "03",
                time: "18:00",
                title: "REVIEW TOMORROW",
                detail: "30 MIN / SOFT",
                lamp: orange,
                panel: panel,
                dark: dark
            )
        }
    }
}

private struct StatusLamp: View {
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay {
                    Circle().stroke(Color.black.opacity(0.35), lineWidth: 1)
                }
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
        }
    }
}

private struct TactileKnob: View {
    let isActive: Bool
    let dark: Color
    let orange: Color

    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Capsule()
                    .fill(dark.opacity(index % 5 == 0 ? 0.62 : 0.25))
                    .frame(width: 2, height: index % 5 == 0 ? 8 : 5)
                    .offset(y: -52)
                    .rotationEffect(.degrees(Double(index) * 18))
            }

            Circle()
                .fill(dark.opacity(0.14))
                .frame(width: 92, height: 92)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.48), dark.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)
                .overlay {
                    Circle().stroke(dark.opacity(0.45), lineWidth: 1)
                }
                .shadow(color: dark.opacity(0.28), radius: 3, y: 3)

            Capsule()
                .fill(isActive ? orange : dark)
                .frame(width: 4, height: 23)
                .offset(y: -17)
                .rotationEffect(.degrees(isActive ? 42 : -42))
        }
        .frame(width: 112, height: 112)
        .animation(.snappy(duration: 0.25), value: isActive)
    }
}

private struct InstrumentTaskChannel: View {
    let channel: String
    let time: String
    let title: String
    let detail: String
    let lamp: Color
    let panel: Color
    let dark: Color

    var body: some View {
        HStack(spacing: 11) {
            Text(channel)
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(dark.opacity(0.48))

            Circle()
                .fill(lamp)
                .frame(width: 10, height: 10)
                .overlay {
                    Circle().stroke(dark.opacity(0.32), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .tracking(0.35)
                Text(detail)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(dark.opacity(0.5))
            }

            Spacer()

            Text(time)
                .font(.subheadline.monospacedDigit().weight(.bold))

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
        }
        .padding(13)
        .background(panel, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(dark.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct InstrumentBottomBar: View {
    let chassis: Color
    let dark: Color
    let orange: Color

    var body: some View {
        HStack(spacing: 8) {
            InstrumentTab(title: "PLAN", icon: "calendar", selected: true, dark: dark, orange: orange)
            InstrumentTab(title: "TASK", icon: "checklist", selected: false, dark: dark, orange: orange)

            Image(systemName: "mic.fill")
                .font(.body.weight(.black))
                .foregroundStyle(Color.white)
                .frame(width: 48, height: 48)
                .background(orange, in: RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(dark.opacity(0.55), lineWidth: 1)
                }

            InstrumentTab(title: "MEM", icon: "memorychip", selected: false, dark: dark, orange: orange)
            InstrumentTab(title: "SET", icon: "gearshape", selected: false, dark: dark, orange: orange)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(chassis)
        .overlay(alignment: .top) {
            Rectangle().fill(dark.opacity(0.42)).frame(height: 1)
        }
    }
}

private struct InstrumentTab: View {
    let title: String
    let icon: String
    let selected: Bool
    let dark: Color
    let orange: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.system(size: 8, weight: .black, design: .monospaced))
        }
        .foregroundStyle(selected ? orange : dark.opacity(0.46))
        .frame(maxWidth: .infinity)
    }
}

#Preview("Quiet Swiss") {
    QuietSwissDemo()
}

#Preview("Seasonal Almanac") {
    SeasonalAlmanacDemo()
}

#Preview("Tactile Instrument") {
    TactileInstrumentDemo(isRecording: .constant(false))
}
