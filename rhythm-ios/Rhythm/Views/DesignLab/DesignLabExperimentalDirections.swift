//
//  DesignLabExperimentalDirections.swift
//  Rhythm
//
//  Isolated visual experiments. These views use deterministic sample content
//  and have no dependency on production models, services, or persistence.
//

import SwiftUI

// MARK: - Direction 7: Transit Day

struct TransitDayDemo: View {
    private let paper = Color(red: 0.96, green: 0.95, blue: 0.90)
    private let navy = Color(red: 0.05, green: 0.11, blue: 0.17)
    private let blue = Color(red: 0.04, green: 0.34, blue: 0.65)
    private let orange = Color(red: 0.91, green: 0.31, blue: 0.10)
    private let green = Color(red: 0.12, green: 0.49, blue: 0.31)

    var body: some View {
        ZStack(alignment: .bottom) {
            paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    transitHeader
                    routeSummary
                    route
                    serviceNote
                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }

            TransitBottomBar(paper: paper, navy: navy, blue: blue)
        }
        .foregroundStyle(navy)
    }

    private var transitHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text("R")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 27, height: 27)
                        .background(blue, in: Circle())

                    Text("RHYTHM TRANSIT")
                        .font(.caption.weight(.black))
                        .tracking(1.4)
                }

                Text("Thursday service")
                    .font(.system(size: 31, weight: .bold))
                    .tracking(-1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("09 JUL")
                    .font(.headline.monospaced())
                Text("ZONE 01")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(navy.opacity(0.48))
            }
        }
        .padding(.bottom, 17)
        .overlay(alignment: .bottom) {
            Rectangle().fill(navy).frame(height: 3)
        }
    }

    private var routeSummary: some View {
        HStack(spacing: 0) {
            TransitMetric(value: "3", label: "STOPS", tint: blue)
            TransitMetric(value: "1", label: "TRANSFER", tint: orange)
            TransitMetric(value: "ON", label: "SERVICE", tint: green)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(navy.opacity(0.18)).frame(height: 1)
        }
    }

    private var route: some View {
        VStack(spacing: 0) {
            TransitRouteRow(
                time: "09:30",
                code: "P1",
                title: "Prepare project notes",
                subtitle: "Current stop · 48 min remaining",
                lineColor: blue,
                isCurrent: true,
                isTransfer: false,
                isLast: false
            )

            TransitRouteRow(
                time: "13:00",
                code: "W2",
                title: "Walk outside",
                subtitle: "Thirty-minute local service",
                lineColor: green,
                isCurrent: false,
                isTransfer: true,
                isLast: false
            )

            TransitOpenSection(navy: navy, orange: orange)

            TransitRouteRow(
                time: "18:00",
                code: "R3",
                title: "Review tomorrow",
                subtitle: "Final stop · flexible arrival",
                lineColor: orange,
                isCurrent: false,
                isTransfer: false,
                isLast: true
            )
        }
        .padding(.top, 8)
    }

    private var serviceNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(blue)

            Text("You can leave the route and rejoin later. No plan is missed.")
                .font(.caption)
                .foregroundStyle(navy.opacity(0.56))

            Spacer()
        }
        .padding(13)
        .background(blue.opacity(0.07))
        .overlay {
            Rectangle().stroke(blue.opacity(0.24), lineWidth: 1)
        }
        .padding(.top, 8)
    }
}

private struct TransitMetric: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.monospaced().weight(.bold))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Color.primary.opacity(0.15)).frame(width: 1)
        }
    }
}

private struct TransitRouteRow: View {
    let time: String
    let code: String
    let title: String
    let subtitle: String
    let lineColor: Color
    let isCurrent: Bool
    let isTransfer: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(time)
                .font(.caption.monospaced().weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.5))
                .frame(width: 42, alignment: .trailing)
                .padding(.top, 19)

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 7, height: isTransfer ? 102 : 88)
                        .offset(y: 25)
                }

                Circle()
                    .fill(isCurrent ? lineColor : Color.white)
                    .frame(width: 27, height: 27)
                    .overlay {
                        Circle().stroke(lineColor, lineWidth: 6)
                    }
                    .padding(.top, 12)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(code)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(lineColor)

                    if isCurrent {
                        Text("YOU ARE HERE")
                            .font(.system(size: 8, weight: .black))
                            .tracking(1)
                            .foregroundStyle(lineColor)
                    }
                }

                Text(title)
                    .font(.body.weight(.bold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.48))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
            }
        }
    }
}

private struct TransitOpenSection: View {
    let navy: Color
    let orange: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("14—17")
                .font(.caption.monospaced())
                .foregroundStyle(navy.opacity(0.5))
                .frame(width: 42, alignment: .trailing)
                .padding(.top, 16)

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(orange)
                    .frame(width: 7, height: 84)
                    .offset(y: 22)

                RoundedRectangle(cornerRadius: 2)
                    .fill(.white)
                    .frame(width: 25, height: 25)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2).stroke(orange, lineWidth: 5)
                    }
                    .rotationEffect(.degrees(45))
                    .padding(.top, 10)
            }
            .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text("TRANSFER")
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(orange)
                Text("Open track")
                    .font(.body.weight(.bold))
                Text("Nothing scheduled · change lines freely")
                    .font(.caption)
                    .foregroundStyle(navy.opacity(0.48))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
        }
    }
}

private struct TransitBottomBar: View {
    let paper: Color
    let navy: Color
    let blue: Color

    var body: some View {
        HStack(spacing: 0) {
            TransitTab(title: "ROUTE", icon: "point.topleft.down.to.point.bottomright.curvepath", selected: true, navy: navy, blue: blue)
            TransitTab(title: "STOPS", icon: "list.bullet", selected: false, navy: navy, blue: blue)

            Image(systemName: "mic.fill")
                .font(.body.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(blue, in: Circle())
                .overlay {
                    Circle().stroke(paper, lineWidth: 4)
                }

            TransitTab(title: "HISTORY", icon: "clock.arrow.circlepath", selected: false, navy: navy, blue: blue)
            TransitTab(title: "INFO", icon: "info.circle", selected: false, navy: navy, blue: blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(paper)
        .overlay(alignment: .top) {
            Rectangle().fill(navy).frame(height: 3)
        }
    }
}

private struct TransitTab: View {
    let title: String
    let icon: String
    let selected: Bool
    let navy: Color
    let blue: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.system(size: 8, weight: .black))
                .tracking(0.6)
        }
        .foregroundStyle(selected ? blue : navy.opacity(0.46))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Direction 8: Rhythm Score

struct RhythmScoreDemo: View {
    @Binding var isPlaying: Bool

    private let black = Color(red: 0.08, green: 0.09, blue: 0.08)
    private let cream = Color(red: 0.94, green: 0.91, blue: 0.80)
    private let lime = Color(red: 0.75, green: 0.82, blue: 0.25)
    private let coral = Color(red: 0.91, green: 0.34, blue: 0.23)
    private let cyan = Color(red: 0.22, green: 0.68, blue: 0.67)

    var body: some View {
        ZStack(alignment: .bottom) {
            black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    scoreHeader
                    transport
                    currentMeasure
                    sequencer
                    restMeasure
                    Color.clear.frame(height: 86)
                }
                .padding(.horizontal, 17)
                .padding(.top, 17)
            }

            ScoreBottomBar(black: black, cream: cream, coral: coral, isPlaying: $isPlaying)
        }
        .foregroundStyle(cream)
    }

    private var scoreHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("RHYTHM / DAY SCORE")
                    .font(.caption.weight(.black))
                    .tracking(1.6)
                Text("Thursday session")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("09 JUL")
                    .font(.headline.monospaced())
                Text("TAKE 01")
                    .font(.caption2.monospaced())
                    .foregroundStyle(cream.opacity(0.45))
            }
        }
    }

    private var transport: some View {
        HStack {
            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .foregroundStyle(black)
                    .frame(width: 48, height: 48)
                    .background(lime, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause score" : "Play score")

            VStack(alignment: .leading, spacing: 2) {
                Text(isPlaying ? "PLAYING" : "READY")
                    .font(.caption2.weight(.black))
                    .tracking(1.4)
                    .foregroundStyle(lime)
                Text("09:42:16")
                    .font(.title2.monospacedDigit().weight(.medium))
            }

            Spacer()

            ScoreReadout(value: "72", label: "PACE", color: cream)
            ScoreReadout(value: "3/4", label: "EVENTS", color: cream)
        }
        .padding(13)
        .background(cream.opacity(0.06))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(cream.opacity(0.18), lineWidth: 1)
        }
    }

    private var currentMeasure: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MEASURE 01 · NOW")
                    .font(.caption2.weight(.black))
                    .tracking(1.2)
                    .foregroundStyle(coral)
                Spacer()
                Text("48 MIN")
                    .font(.caption.monospaced())
                    .foregroundStyle(cream.opacity(0.46))
            }

            Text("Prepare project notes")
                .font(.title2.weight(.bold))

            Text("Start with one open question")
                .font(.subheadline)
                .foregroundStyle(cream.opacity(0.55))

            HStack(spacing: 4) {
                ForEach(0..<16, id: \.self) { index in
                    Rectangle()
                        .fill(index < 10 ? coral : cream.opacity(0.13))
                        .frame(maxWidth: .infinity)
                        .frame(height: index % 4 == 0 ? 17 : 9)
                }
            }
            .frame(height: 18, alignment: .bottom)
        }
        .padding(15)
        .background(coral.opacity(0.08))
        .overlay(alignment: .leading) {
            Rectangle().fill(coral).frame(width: 4)
        }
    }

    private var sequencer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ARRANGEMENT")
                    .font(.caption2.weight(.black))
                    .tracking(1.4)
                Spacer()
                Text("10:00—20:00")
                    .font(.caption2.monospaced())
                    .foregroundStyle(cream.opacity(0.42))
            }

            ScoreTrack(name: "MOVE", activeRange: 2...3, tint: cyan, cream: cream)
            ScoreTrack(name: "OPEN", activeRange: 4...6, tint: lime, cream: cream)
            ScoreTrack(name: "CLOSE", activeRange: 7...7, tint: coral, cream: cream)
        }
    }

    private var restMeasure: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "pause")
                .font(.title3.weight(.black))
                .foregroundStyle(lime)
                .frame(width: 42, height: 42)
                .overlay {
                    Circle().stroke(lime.opacity(0.5), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("REST · 14:00—17:30")
                    .font(.caption2.weight(.black))
                    .tracking(1)
                    .foregroundStyle(lime)
                Text("Silence is part of the score.")
                    .font(.body.weight(.semibold))
                Text("No event needs to be added.")
                    .font(.caption)
                    .foregroundStyle(cream.opacity(0.45))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct ScoreReadout: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .black))
                .tracking(0.8)
                .foregroundStyle(color.opacity(0.48))
        }
    }
}

private struct ScoreTrack: View {
    let name: String
    let activeRange: ClosedRange<Int>
    let tint: Color
    let cream: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(name)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(cream.opacity(0.56))
                .frame(width: 38, alignment: .leading)

            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(activeRange.contains(index) ? tint : cream.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 35)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(cream.opacity(0.12), lineWidth: 1)
                    }
            }
        }
    }
}

private struct ScoreBottomBar: View {
    let black: Color
    let cream: Color
    let coral: Color
    @Binding var isPlaying: Bool

    var body: some View {
        HStack {
            ScoreTab(title: "SCORE", icon: "music.note.list", selected: true, cream: cream, coral: coral)
            ScoreTab(title: "TRACKS", icon: "slider.horizontal.3", selected: false, cream: cream, coral: coral)

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.body.weight(.black))
                    .foregroundStyle(black)
                    .frame(width: 52, height: 52)
                    .background(coral, in: Circle())
            }
            .buttonStyle(.plain)

            ScoreTab(title: "MEMORY", icon: "waveform.path", selected: false, cream: cream, coral: coral)
            ScoreTab(title: "SET", icon: "gearshape", selected: false, cream: cream, coral: coral)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(black)
        .overlay(alignment: .top) {
            Rectangle().fill(cream.opacity(0.22)).frame(height: 1)
        }
    }
}

private struct ScoreTab: View {
    let title: String
    let icon: String
    let selected: Bool
    let cream: Color
    let coral: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.system(size: 8, weight: .black, design: .monospaced))
        }
        .foregroundStyle(selected ? coral : cream.opacity(0.42))
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Direction 9: Soft Atelier

struct SoftAtelierDemo: View {
    private let clay = Color(red: 0.91, green: 0.86, blue: 0.76)
    private let bone = Color(red: 0.97, green: 0.94, blue: 0.87)
    private let cobalt = Color(red: 0.12, green: 0.27, blue: 0.63)
    private let terracotta = Color(red: 0.76, green: 0.31, blue: 0.19)
    private let olive = Color(red: 0.40, green: 0.46, blue: 0.26)
    private let ink = Color(red: 0.16, green: 0.14, blue: 0.12)

    var body: some View {
        ZStack(alignment: .bottom) {
            clay.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    atelierHeader
                    currentPiece
                    upcomingPieces
                    openStudio
                    Color.clear.frame(height: 88)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
            }

            AtelierBottomBar(bone: bone, ink: ink, cobalt: cobalt)
        }
        .foregroundStyle(ink)
    }

    private var atelierHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("THURSDAY · 09 JUL")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(cobalt)

                Text("A day with room\naround it.")
                    .font(.system(size: 34, weight: .medium, design: .serif))
                    .tracking(-0.7)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(terracotta)
                    .frame(width: 45, height: 45)
                    .offset(x: 8, y: 13)
                RoundedRectangle(cornerRadius: 12)
                    .fill(cobalt)
                    .frame(width: 46, height: 64)
                    .rotationEffect(.degrees(8))
            }
            .frame(width: 68, height: 76)
        }
    }

    private var currentPiece: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack {
                Text("NOW · 09:30—10:30")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                Spacer()
                Text("48 min")
                    .font(.caption.monospacedDigit())
                    .opacity(0.65)
            }

            Text("Prepare\nproject notes")
                .font(.system(size: 31, weight: .medium, design: .serif))
                .lineSpacing(-2)

            Text("Begin with one open question.")
                .font(.subheadline)
                .opacity(0.68)

            HStack {
                Button("Begin") {}
                    .buttonStyle(AtelierActionStyle())
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.headline)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(cobalt, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(bone.opacity(0.18))
                .frame(width: 108, height: 108)
                .offset(x: 28, y: 34)
        }
        .clipped()
        .shadow(color: ink.opacity(0.14), radius: 0, y: 5)
    }

    private var upcomingPieces: some View {
        HStack(alignment: .top, spacing: 12) {
            AtelierPiece(
                time: "13:00",
                title: "Walk\noutside",
                note: "30 min",
                background: terracotta,
                foreground: bone,
                shape: .circle
            )

            AtelierPiece(
                time: "18:00",
                title: "Review\ntomorrow",
                note: "Soft close",
                background: bone,
                foreground: ink,
                shape: .arch
            )
        }
    }

    private var openStudio: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(olive)
                    .frame(width: 70, height: 70)
                Circle()
                    .stroke(bone.opacity(0.55), lineWidth: 1)
                    .frame(width: 48, height: 48)
                Image(systemName: "wind")
                    .foregroundStyle(bone)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("14:00—17:30")
                    .font(.caption.monospaced())
                    .foregroundStyle(olive)
                Text("Open studio")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                Text("Leave the table clear.")
                    .font(.caption)
                    .foregroundStyle(ink.opacity(0.5))
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct AtelierActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .overlay {
                Capsule().stroke(Color.white.opacity(0.65), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

private enum AtelierPieceShape {
    case circle
    case arch
}

private struct AtelierPiece: View {
    let time: String
    let title: String
    let note: String
    let background: Color
    let foreground: Color
    let shape: AtelierPieceShape

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(time)
                .font(.caption.monospacedDigit())
                .opacity(0.7)

            Spacer()

            Text(title)
                .font(.system(size: 23, weight: .medium, design: .serif))

            Text(note)
                .font(.caption)
                .opacity(0.6)
        }
        .foregroundStyle(foreground)
        .padding(17)
        .frame(maxWidth: .infinity, minHeight: 174, alignment: .leading)
        .background {
            if shape == .circle {
                RoundedRectangle(cornerRadius: 72, style: .continuous)
                    .fill(background)
            } else {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .fill(background)
            }
        }
        .overlay {
            if shape == .arch {
                RoundedRectangle(cornerRadius: 27, style: .continuous)
                    .stroke(foreground.opacity(0.16), lineWidth: 1)
            }
        }
    }
}

private struct AtelierBottomBar: View {
    let bone: Color
    let ink: Color
    let cobalt: Color

    var body: some View {
        HStack {
            AtelierTab(title: "Today", icon: "circle.fill", selected: true, ink: ink, cobalt: cobalt)
            AtelierTab(title: "Tasks", icon: "square.fill", selected: false, ink: ink, cobalt: cobalt)

            Image(systemName: "mic.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(bone)
                .frame(width: 54, height: 54)
                .background(cobalt, in: Circle())

            AtelierTab(title: "Memory", icon: "triangle.fill", selected: false, ink: ink, cobalt: cobalt)
            AtelierTab(title: "More", icon: "diamond.fill", selected: false, ink: ink, cobalt: cobalt)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(bone)
        .overlay(alignment: .top) {
            Rectangle().fill(ink.opacity(0.14)).frame(height: 1)
        }
    }
}

private struct AtelierTab: View {
    let title: String
    let icon: String
    let selected: Bool
    let ink: Color
    let cobalt: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .serif))
        }
        .foregroundStyle(selected ? cobalt : ink.opacity(0.42))
        .frame(maxWidth: .infinity)
    }
}

#Preview("Transit Day") {
    TransitDayDemo()
}

#Preview("Rhythm Score") {
    RhythmScoreDemo(isPlaying: .constant(false))
}

#Preview("Soft Atelier") {
    SoftAtelierDemo()
}
