//
//  DesignLabView.swift
//  Rhythm
//
//  A lightweight gallery for comparing future visual directions.
//

import SwiftUI

struct DesignLabView: View {
    @State private var direction: DesignDirection
    @State private var isVoiceDemoListening = false
    @State private var isInstrumentRecording = false
    @State private var isScorePlaying = false

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let requestedDirection = ProcessInfo.processInfo.environment["DESIGN_LAB_DIRECTION"]
        let initialDirection: DesignDirection

        if requestedDirection == "atelier" {
            initialDirection = .softAtelier
        } else if requestedDirection == "score" {
            initialDirection = .rhythmScore
        } else if requestedDirection == "transit" {
            initialDirection = .transitDay
        } else if arguments.contains("-designSwiss") {
            initialDirection = .quietSwiss
        } else if arguments.contains("-designAlmanac") {
            initialDirection = .seasonalAlmanac
        } else if arguments.contains("-designInstrument") {
            initialDirection = .tactileInstrument
        } else if arguments.contains("-designTransit") {
            initialDirection = .transitDay
        } else if arguments.contains("-designScore") {
            initialDirection = .rhythmScore
        } else if arguments.contains("-designAtelier") {
            initialDirection = .softAtelier
        } else if arguments.contains("-designFlow") {
            initialDirection = .livingTimeline
        } else if arguments.contains("-designVoice") {
            initialDirection = .voiceAtmosphere
        } else {
            initialDirection = .paperAgenda
        }

        _direction = State(initialValue: initialDirection)
    }

    var body: some View {
        VStack(spacing: 0) {
            directionPicker

            Group {
                switch direction {
                case .paperAgenda:
                    PaperAgendaDemo()
                case .livingTimeline:
                    LivingTimelineDemo()
                case .voiceAtmosphere:
                    VoiceAtmosphereDemo(isListening: $isVoiceDemoListening)
                case .quietSwiss:
                    QuietSwissDemo()
                case .seasonalAlmanac:
                    SeasonalAlmanacDemo()
                case .tactileInstrument:
                    TactileInstrumentDemo(isRecording: $isInstrumentRecording)
                case .transitDay:
                    TransitDayDemo()
                case .rhythmScore:
                    RhythmScoreDemo(isPlaying: $isScorePlaying)
                case .softAtelier:
                    SoftAtelierDemo()
                }
            }
            .id(direction)
            .transition(.opacity.combined(with: .scale(scale: 0.985)))
        }
        .background(direction.chromeColor)
        .navigationTitle("Design Lab")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .animation(.snappy(duration: 0.28), value: direction)
    }

    private var directionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(direction.designIdea)
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .contentTransition(.numericText())

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DesignDirection.allCases) { item in
                            Button {
                                direction = item
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: item.icon)
                                        .font(.subheadline.weight(.semibold))

                                    Text(item.shortTitle)
                                        .font(.caption2.weight(.semibold))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(direction == item ? Color.white : Color.primary.opacity(0.62))
                                .frame(width: 96)
                                .padding(.vertical, 9)
                                .background {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(direction == item ? item.accentColor : Color.primary.opacity(0.055))
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.title)
                            .id(item)
                        }
                    }
                }
                .contentMargins(.horizontal, 1)
                .onAppear {
                    proxy.scrollTo(direction, anchor: .center)
                }
                .onChange(of: direction) { _, newValue in
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.35)
        }
    }
}

private enum DesignDirection: String, CaseIterable, Identifiable {
    case paperAgenda
    case livingTimeline
    case voiceAtmosphere
    case quietSwiss
    case seasonalAlmanac
    case tactileInstrument
    case transitDay
    case rhythmScore
    case softAtelier

    var id: Self { self }

    var title: String {
        switch self {
        case .paperAgenda: "Paper Agenda"
        case .livingTimeline: "Living Timeline"
        case .voiceAtmosphere: "Voice Atmosphere"
        case .quietSwiss: "Quiet Swiss"
        case .seasonalAlmanac: "Seasonal Almanac"
        case .tactileInstrument: "Tactile Instrument"
        case .transitDay: "Transit Day"
        case .rhythmScore: "Rhythm Score"
        case .softAtelier: "Soft Atelier"
        }
    }

    var shortTitle: String {
        switch self {
        case .paperAgenda: "Editorial"
        case .livingTimeline: "Flow"
        case .voiceAtmosphere: "Voice"
        case .quietSwiss: "Swiss"
        case .seasonalAlmanac: "Almanac"
        case .tactileInstrument: "Instrument"
        case .transitDay: "Transit"
        case .rhythmScore: "Score"
        case .softAtelier: "Atelier"
        }
    }

    var designIdea: String {
        switch self {
        case .paperAgenda:
            "01 · Typography first, like a calm personal agenda"
        case .livingTimeline:
            "02 · Time becomes a path instead of a rigid calendar grid"
        case .voiceAtmosphere:
            "03 · AI is expressed through presence, sound, and changing light"
        case .quietSwiss:
            "04 · A precise tool where typography and time do the work"
        case .seasonalAlmanac:
            "05 · Planning as a seasonal page with meaningful empty space"
        case .tactileInstrument:
            "06 · Physical controls, signal lights, and dependable feedback"
        case .transitDay:
            "07 · The day as a route: clear stops, transfers, and open track"
        case .rhythmScore:
            "08 · Plans arranged like music: tracks, measures, and rests"
        case .softAtelier:
            "09 · Sculptural shapes, domestic warmth, and generous breathing room"
        }
    }

    var icon: String {
        switch self {
        case .paperAgenda: "text.alignleft"
        case .livingTimeline: "point.topleft.down.to.point.bottomright.curvepath"
        case .voiceAtmosphere: "waveform"
        case .quietSwiss: "rectangle.split.3x1"
        case .seasonalAlmanac: "leaf"
        case .tactileInstrument: "dial.medium"
        case .transitDay: "point.bottomleft.forward.to.point.topright.scurvepath"
        case .rhythmScore: "music.note.list"
        case .softAtelier: "square.on.circle"
        }
    }

    var accentColor: Color {
        switch self {
        case .paperAgenda: Color(red: 0.79, green: 0.31, blue: 0.20)
        case .livingTimeline: Color(red: 0.16, green: 0.38, blue: 0.32)
        case .voiceAtmosphere: Color(red: 0.69, green: 0.35, blue: 0.42)
        case .quietSwiss: Color(red: 0.78, green: 0.16, blue: 0.09)
        case .seasonalAlmanac: Color(red: 0.42, green: 0.47, blue: 0.29)
        case .tactileInstrument: Color(red: 0.88, green: 0.29, blue: 0.12)
        case .transitDay: Color(red: 0.05, green: 0.33, blue: 0.62)
        case .rhythmScore: Color(red: 0.75, green: 0.82, blue: 0.25)
        case .softAtelier: Color(red: 0.13, green: 0.28, blue: 0.63)
        }
    }

    var chromeColor: Color {
        switch self {
        case .paperAgenda: Color(red: 0.96, green: 0.92, blue: 0.84)
        case .livingTimeline: Color(red: 0.87, green: 0.91, blue: 0.84)
        case .voiceAtmosphere: Color(red: 0.12, green: 0.09, blue: 0.14)
        case .quietSwiss: Color(red: 0.95, green: 0.95, blue: 0.92)
        case .seasonalAlmanac: Color(red: 0.93, green: 0.89, blue: 0.79)
        case .tactileInstrument: Color(red: 0.74, green: 0.72, blue: 0.66)
        case .transitDay: Color(red: 0.94, green: 0.93, blue: 0.88)
        case .rhythmScore: Color(red: 0.10, green: 0.11, blue: 0.10)
        case .softAtelier: Color(red: 0.91, green: 0.86, blue: 0.76)
        }
    }
}

// MARK: - Direction 1: Paper Agenda

private struct PaperAgendaDemo: View {
    private let ink = Color(red: 0.17, green: 0.15, blue: 0.13)
    private let rust = Color(red: 0.79, green: 0.31, blue: 0.20)
    private let paper = Color(red: 0.98, green: 0.95, blue: 0.88)

    var body: some View {
        ZStack(alignment: .bottom) {
            paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    dateHeader
                    dayStatement
                    currentCommitment
                    laterSection
                    Color.clear.frame(height: 92)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
            }

            DemoBottomBar(
                selected: "Plan",
                tint: rust,
                background: paper.opacity(0.96),
                foreground: ink
            )
        }
        .foregroundStyle(ink)
    }

    private var dateHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("THURSDAY")
                    .font(.caption2.weight(.bold))
                    .tracking(2.2)

                Text("JUL 9")
                    .font(.caption)
                    .foregroundStyle(ink.opacity(0.5))
            }

            Spacer()

            Text("72°  ·  Quiet morning")
                .font(.caption)
                .foregroundStyle(ink.opacity(0.58))
        }
    }

    private var dayStatement: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A lighter day.")
                .font(.system(size: 39, weight: .medium, design: .serif))
                .tracking(-1.2)

            Text("Three things have a place. The rest can wait.")
                .font(.callout)
                .foregroundStyle(ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(ink.opacity(0.75))
                .frame(height: 1)
                .padding(.top, 4)
        }
    }

    private var currentCommitment: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("NOW · UNTIL 10:30", systemImage: "circle.fill")
                    .font(.caption2.weight(.bold))
                    .tracking(1.15)
                    .foregroundStyle(rust)

                Spacer()

                Text("48 min")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(ink.opacity(0.5))
            }

            Text("Prepare project notes")
                .font(.system(size: 25, weight: .semibold, design: .serif))

            Text("Begin with the open questions from yesterday.")
                .font(.subheadline)
                .foregroundStyle(ink.opacity(0.6))

            HStack(spacing: 10) {
                Button("Begin gently") {}
                    .buttonStyle(PaperButtonStyle(filled: true, ink: ink, paper: paper))

                Button("Move later") {}
                    .buttonStyle(PaperButtonStyle(filled: false, ink: ink, paper: paper))
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.38))
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(rust)
                .frame(width: 4)
        }
    }

    private var laterSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("LATER")
                .font(.caption2.weight(.bold))
                .tracking(2)
                .padding(.bottom, 6)

            AgendaRow(time: "1:00", title: "Walk outside", detail: "30 minutes", ink: ink, accent: Color(red: 0.32, green: 0.48, blue: 0.35))
            AgendaRow(time: "6:00", title: "Review tomorrow", detail: "A soft landing", ink: ink, accent: rust)
        }
    }
}

private struct PaperButtonStyle: ButtonStyle {
    let filled: Bool
    let ink: Color
    let paper: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundStyle(filled ? paper : ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(filled ? ink : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(ink.opacity(filled ? 0 : 0.35), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.64 : 1)
    }
}

private struct AgendaRow: View {
    let time: String
    let title: String
    let detail: String
    let ink: Color
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(time)
                .font(.subheadline.monospacedDigit())
                .frame(width: 42, alignment: .leading)

            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ink.opacity(0.48))
            }

            Spacer()
        }
        .padding(.vertical, 15)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ink.opacity(0.13))
                .frame(height: 1)
        }
    }
}

// MARK: - Direction 2: Living Timeline

private struct LivingTimelineDemo: View {
    private let forest = Color(red: 0.10, green: 0.28, blue: 0.23)
    private let moss = Color(red: 0.42, green: 0.58, blue: 0.43)
    private let ground = Color(red: 0.90, green: 0.93, blue: 0.85)
    private let sun = Color(red: 0.95, green: 0.64, blue: 0.31)

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [ground, Color(red: 0.82, green: 0.89, blue: 0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    flowHeader
                    nowCard
                    timeline
                    Color.clear.frame(height: 92)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            DemoBottomBar(
                selected: "Plan",
                tint: forest,
                background: ground.opacity(0.9),
                foreground: forest
            )
        }
        .foregroundStyle(forest)
    }

    private var flowHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Today’s rhythm")
                    .font(.system(size: 31, weight: .bold, design: .rounded))

                Text("Planned enough to feel held.")
                    .font(.subheadline)
                    .foregroundStyle(forest.opacity(0.58))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(forest.opacity(0.12), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: 0.62)
                    .stroke(sun, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("3")
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 50, height: 50)
        }
    }

    private var nowCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("In your flow", systemImage: "water.waves")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(moss)

                Spacer()

                Text("9:42")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(forest.opacity(0.52))
            }

            Text("Prepare project notes")
                .font(.title3.weight(.bold))

            HStack {
                Text("One open question is enough to begin.")
                    .font(.subheadline)
                    .foregroundStyle(forest.opacity(0.6))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .background(sun, in: Circle())
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THE DAY AHEAD")
                .font(.caption2.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(forest.opacity(0.5))

            FlowRow(
                time: "1:00",
                title: "Walk outside",
                note: "A small reset",
                color: moss,
                lineColor: forest.opacity(0.18),
                isLast: false
            )

            FlowRow(
                time: "4:30",
                title: "Open space",
                note: "Nothing needs to fill this",
                color: Color.white.opacity(0.8),
                lineColor: forest.opacity(0.18),
                isLast: false
            )

            FlowRow(
                time: "6:00",
                title: "Review tomorrow",
                note: "Close the loop",
                color: sun,
                lineColor: forest.opacity(0.18),
                isLast: true
            )
        }
    }
}

private struct FlowRow: View {
    let time: String
    let title: String
    let note: String
    let color: Color
    let lineColor: Color
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color.primary.opacity(0.5))
                .frame(width: 36, alignment: .trailing)
                .padding(.top, 16)

            ZStack(alignment: .top) {
                if !isLast {
                    Capsule()
                        .fill(lineColor)
                        .frame(width: 3, height: 84)
                        .offset(y: 24)
                }

                Circle()
                    .fill(color)
                    .frame(width: 17, height: 17)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.8), lineWidth: 3)
                    }
                    .padding(.top, 16)
            }
            .frame(width: 18)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))

                Text(note)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.52))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

// MARK: - Direction 3: Voice Atmosphere

private struct VoiceAtmosphereDemo: View {
    @Binding var isListening: Bool

    private let night = Color(red: 0.12, green: 0.08, blue: 0.14)
    private let blush = Color(red: 0.92, green: 0.45, blue: 0.42)
    private let peach = Color(red: 0.98, green: 0.70, blue: 0.43)
    private let mint = Color(red: 0.55, green: 0.77, blue: 0.65)

    var body: some View {
        ZStack(alignment: .bottom) {
            atmosphericBackground

            ScrollView {
                VStack(spacing: 24) {
                    voiceHeader
                    voiceOrb
                    listeningCopy
                    suggestionStrip
                    nextCard
                    Color.clear.frame(height: 92)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            DemoBottomBar(
                selected: "Add",
                tint: blush,
                background: night.opacity(0.84),
                foreground: .white
            )
        }
        .foregroundStyle(Color.white)
    }

    private var atmosphericBackground: some View {
        ZStack {
            night

            Circle()
                .fill(blush.opacity(isListening ? 0.46 : 0.25))
                .frame(width: 330, height: 330)
                .blur(radius: 72)
                .offset(x: -125, y: -260)

            Circle()
                .fill(mint.opacity(isListening ? 0.32 : 0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 150, y: 220)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.8), value: isListening)
    }

    private var voiceHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rhythm is listening")
                    .font(.title2.weight(.semibold))

                Text("Say what is on your mind.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.56))
            }

            Spacer()

            Image(systemName: "ellipsis")
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.09), in: Circle())
        }
    }

    private var voiceOrb: some View {
        Button {
            isListening.toggle()
        } label: {
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [blush.opacity(0.55), peach.opacity(0.15), mint.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(
                            width: CGFloat(150 + ring * 30),
                            height: CGFloat(150 + ring * 30)
                        )
                        .scaleEffect(isListening ? 1.04 + CGFloat(ring) * 0.025 : 1)
                        .opacity(1 - Double(ring) * 0.25)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [peach, blush, Color(red: 0.48, green: 0.20, blue: 0.38)],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 90
                        )
                    )
                    .frame(width: 124, height: 124)
                    .shadow(color: blush.opacity(0.5), radius: 28)

                Image(systemName: isListening ? "waveform" : "mic.fill")
                    .font(.system(size: 31, weight: .medium))
            }
            .frame(height: 220)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isListening ? "Stop listening" : "Start listening")
    }

    private var listeningCopy: some View {
        VStack(spacing: 6) {
            Text(isListening ? "“Tomorrow afternoon, remind me to…”" : "Tap to speak")
                .font(isListening ? .body : .title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            Text(isListening ? "Listening for the shape of your plan" : "Or choose a thought starter below")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }

    private var suggestionStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                VoiceSuggestion(title: "Plan tomorrow", icon: "sunrise", tint: peach)
                VoiceSuggestion(title: "Move something", icon: "arrow.right", tint: mint)
                VoiceSuggestion(title: "Clear my head", icon: "wind", tint: blush)
            }
        }
        .contentMargins(.horizontal, 1)
    }

    private var nextCard: some View {
        HStack(spacing: 13) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT GENTLE NUDGE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(peach)

                Text("Walk outside")
                    .font(.body.weight(.semibold))

                Text("Around 1:00 PM · flexible")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.48))
            }

            Spacer()

            Image(systemName: "leaf.fill")
                .foregroundStyle(mint)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.08), in: Circle())
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        }
    }
}

private struct VoiceSuggestion: View {
    let title: String
    let icon: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.86))
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay {
                Capsule().stroke(tint.opacity(0.24), lineWidth: 1)
            }
    }
}

// MARK: - Shared demo navigation

private struct DemoBottomBar: View {
    let selected: String
    let tint: Color
    let background: Color
    let foreground: Color

    private let items = [
        ("Plan", "calendar"),
        ("Tasks", "checklist"),
        ("Add", "mic.fill"),
        ("Memory", "brain.head.profile"),
        ("Settings", "gearshape")
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 4) {
                    Image(systemName: item.1)
                        .font(item.0 == "Add" ? .body.weight(.bold) : .caption.weight(.semibold))
                        .frame(width: item.0 == "Add" ? 42 : 28, height: item.0 == "Add" ? 42 : 28)
                        .background(item.0 == "Add" ? tint : Color.clear, in: Circle())
                        .foregroundStyle(item.0 == "Add" ? Color.white : (selected == item.0 ? tint : foreground.opacity(0.5)))

                    if item.0 != "Add" {
                        Text(item.0)
                            .font(.system(size: 9, weight: selected == item.0 ? .bold : .medium))
                            .foregroundStyle(selected == item.0 ? tint : foreground.opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(background)
        .overlay(alignment: .top) {
            Divider().opacity(0.18)
        }
    }
}

#Preview("Design Lab") {
    NavigationStack {
        DesignLabView()
    }
}
