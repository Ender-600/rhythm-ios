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
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.rhythmCoral.opacity(0.2), .rhythmAmber.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.rhythmCoral, .rhythmAmber],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Text
                    VStack(spacing: 12) {
                        Text(Copy.Memory.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.rhythmTextPrimary)
                        
                        Text(Copy.Memory.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                    
                    // Teaser
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Copy.Memory.comingSoon)
                            .font(.headline)
                            .foregroundColor(.rhythmCoral)
                        
                        Text(Copy.Memory.teaser)
                            .font(.body)
                            .foregroundColor(.rhythmTextSecondary)
                            .multilineTextAlignment(.center)
                        
                        // Future features teaser
                        VStack(alignment: .leading, spacing: 12) {
                            featureTeaser(icon: "chart.line.uptrend.xyaxis", text: "Your productivity patterns")
                            featureTeaser(icon: "clock.arrow.circlepath", text: "Snooze habits & insights")
                            featureTeaser(icon: "lightbulb", text: "Personalized suggestions")
                            featureTeaser(icon: "calendar.badge.clock", text: "Best times for deep work")
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.rhythmCard(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationTitle(Copy.Memory.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func featureTeaser(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.rhythmCoral)
                .frame(width: 28)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.rhythmTextPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MemoryView()
}

