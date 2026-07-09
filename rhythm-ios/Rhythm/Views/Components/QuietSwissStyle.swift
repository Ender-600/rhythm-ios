//
//  QuietSwissStyle.swift
//  Rhythm
//
//  Shared visual primitives for the production Quiet Swiss interface.
//

import SwiftUI

enum QuietSwiss {
    static let screenPadding: CGFloat = 20
    static let compactRadius: CGFloat = 2
    static let controlHeight: CGFloat = 48
    static let ruleWidth: CGFloat = 1
}

struct SwissSectionLabel: View {
    let title: String
    var trailingText: String?
    var color: Color = .rhythmTextPrimary

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .tracking(1.6)
                .foregroundStyle(color)

            Spacer()

            if let trailingText {
                Text(trailingText.uppercased())
                    .font(.caption2.monospaced())
                    .foregroundStyle(Color.rhythmTextMuted)
            }
        }
    }
}

struct SwissRule: View {
    @Environment(\.colorScheme) private var colorScheme
    var strong = false

    var body: some View {
        Rectangle()
            .fill(strong ? Color.rhythmTextPrimary : Color.rhythmRule(for: colorScheme))
            .frame(height: strong ? 2 : QuietSwiss.ruleWidth)
    }
}

private struct SwissSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let accent: Color?
    let filled: Bool

    func body(content: Content) -> some View {
        content
            .background(filled ? Color.rhythmCard(for: colorScheme) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: QuietSwiss.compactRadius))
            .overlay {
                RoundedRectangle(cornerRadius: QuietSwiss.compactRadius)
                    .stroke(accent ?? Color.rhythmRule(for: colorScheme), lineWidth: accent == nil ? 1 : 2)
            }
    }
}

private struct SwissScreenModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.rhythmBackground(for: colorScheme))
            .tint(.rhythmSignal)
    }
}

extension View {
    func swissSurface(accent: Color? = nil, filled: Bool = true) -> some View {
        modifier(SwissSurfaceModifier(accent: accent, filled: filled))
    }

    func swissScreen() -> some View {
        modifier(SwissScreenModifier())
    }

    func swissSectionLabel(color: Color = .rhythmTextPrimary) -> some View {
        font(.caption2.weight(.black))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SwissSectionLabel(title: "Today", trailingText: "03 items")
        SwissRule(strong: true)
        Text("A precise surface")
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .swissSurface(accent: .rhythmSignal)
    }
    .padding()
    .swissScreen()
}
