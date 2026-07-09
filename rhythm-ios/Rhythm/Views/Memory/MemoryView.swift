//
//  MemoryView.swift
//  Rhythm
//
//  Placeholder for future retrospective/memory features
//  Will show patterns, insights, and learning from user behavior
//

import SwiftUI

struct MemoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.rhythmBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MEMORY / PATTERNS")
                                    .swissSectionLabel(color: .rhythmSignal)

                                Text("A record of\nyour rhythm.")
                                    .font(.system(size: 36, weight: .bold))
                                    .tracking(-1.2)
                                    .foregroundStyle(Color.rhythmTextPrimary)
                            }

                            Spacer()

                            Text("M")
                                .font(.title2.monospaced().weight(.black))
                                .foregroundStyle(Color.rhythmPaper)
                                .frame(width: 56, height: 56)
                                .background(Color.rhythmInk)
                        }

                        SwissRule(strong: true)

                        Text(Copy.Memory.subtitle)
                            .font(.body)
                            .foregroundStyle(Color.rhythmTextSecondary)

                        VStack(alignment: .leading, spacing: 10) {
                            SwissSectionLabel(
                                title: Copy.Memory.comingSoon,
                                trailingText: "04 signals"
                            )

                            Text(Copy.Memory.teaser)
                                .font(.body)
                                .foregroundStyle(Color.rhythmTextSecondary)
                                .padding(.bottom, 6)

                            featureTeaser(index: "01", icon: "chart.line.uptrend.xyaxis", text: "Your productivity patterns")
                            featureTeaser(index: "02", icon: "clock.arrow.circlepath", text: "Snooze habits & insights")
                            featureTeaser(index: "03", icon: "lightbulb", text: "Personalized suggestions")
                            featureTeaser(index: "04", icon: "calendar.badge.clock", text: "Best times for deep work")
                        }
                        .padding(18)
                        .swissSurface()
                    }
                    .padding(.horizontal, QuietSwiss.screenPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 110)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func featureTeaser(index: String, icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(index)
                .font(.caption2.monospaced())
                .foregroundStyle(Color.rhythmTextMuted)
                .frame(width: 22, alignment: .leading)

            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.rhythmSignal)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.rhythmTextPrimary)
            
            Spacer()
        }
        .padding(.vertical, 11)
        .overlay(alignment: .top) {
            SwissRule()
        }
    }
}

// MARK: - Preview

#Preview {
    MemoryView()
}
