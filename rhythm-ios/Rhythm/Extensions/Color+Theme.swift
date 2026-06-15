//
//  Color+Theme.swift
//  Rhythm
//
//  Warm, gentle design system - never harsh or commanding
//

import SwiftUI

extension Color {
    // MARK: - Primary Palette (Warm & Inviting)
    
    /// Soft coral - primary accent, warmth without urgency
    static let rhythmCoral = Color(red: 0.95, green: 0.55, blue: 0.47)
    
    /// Warm amber - secondary accent, gentle energy
    static let rhythmAmber = Color(red: 0.96, green: 0.76, blue: 0.42)
    
    /// Soft sage - calm, could-do energy
    static let rhythmSage = Color(red: 0.67, green: 0.78, blue: 0.68)
    
    /// Deep plum - for contrast and depth
    static let rhythmPlum = Color(red: 0.35, green: 0.25, blue: 0.38)
    
    // MARK: - Background Colors
    
    /// Warm off-white for light mode
    static let rhythmCream = Color(red: 0.99, green: 0.97, blue: 0.94)
    
    /// Soft charcoal for dark mode
    static let rhythmCharcoal = Color(red: 0.15, green: 0.14, blue: 0.16)
    
    /// Card background
    static let rhythmCardLight = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let rhythmCardDark = Color(red: 0.20, green: 0.19, blue: 0.21)
    
    // MARK: - Text Colors
    
    /// Primary text - warm, not pure black
    static let rhythmTextPrimary = Color(red: 0.20, green: 0.18, blue: 0.22)
    
    /// Secondary text - softer
    static let rhythmTextSecondary = Color(red: 0.45, green: 0.42, blue: 0.48)
    
    /// Muted text - hints and placeholders
    static let rhythmTextMuted = Color(red: 0.65, green: 0.62, blue: 0.68)
    
    // MARK: - Semantic Colors
    
    /// Success - gentle green
    static let rhythmSuccess = Color(red: 0.52, green: 0.75, blue: 0.56)
    
    /// Warning - soft amber (not alarming)
    static let rhythmWarning = Color(red: 0.94, green: 0.72, blue: 0.38)
    
    /// Error - muted red (not aggressive)
    static let rhythmError = Color(red: 0.85, green: 0.45, blue: 0.45)
    
    // MARK: - Voice Button
    
    /// Recording state - pulsing warmth
    static let rhythmRecording = Color(red: 0.92, green: 0.42, blue: 0.38)
    
    /// Idle state - inviting
    static let rhythmVoiceIdle = Color(red: 0.95, green: 0.55, blue: 0.47)
    
    // MARK: - Chip Colors
    
    /// Signal chip background
    static let rhythmChipBackground = Color(red: 0.96, green: 0.94, blue: 0.91)
    static let rhythmChipBackgroundDark = Color(red: 0.25, green: 0.24, blue: 0.26)
}

// MARK: - Adaptive Colors

extension Color {
    /// Adaptive background based on color scheme
    static func rhythmBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .rhythmCharcoal : .rhythmCream
    }
    
    /// Adaptive card background
    static func rhythmCard(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .rhythmCardDark : .rhythmCardLight
    }
    
    /// Adaptive chip background
    static func rhythmChip(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .rhythmChipBackgroundDark : .rhythmChipBackground
    }
}

// MARK: - Gradient Presets

extension LinearGradient {
    /// Warm sunrise gradient for headers
    static let rhythmSunrise = LinearGradient(
        colors: [.rhythmCoral.opacity(0.8), .rhythmAmber.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Calm evening gradient
    static let rhythmEvening = LinearGradient(
        colors: [.rhythmPlum.opacity(0.7), .rhythmCoral.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Voice button gradient
    static let rhythmVoice = LinearGradient(
        colors: [.rhythmCoral, .rhythmAmber.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Theme Namespace

extension Color {
    struct Theme {
        // Primary colors
        let primary: Color
        let secondary: Color
        let accent: Color
        
        // Backgrounds
        let background: Color
        let cardBackground: Color
        
        // Text
        let text: Color
        let textSecondary: Color
        let textMuted: Color
        
        // UI Elements
        let border: Color
        let success: Color
        let warning: Color
        let error: Color
        
        static let light = Theme(
            primary: .rhythmCoral,
            secondary: .rhythmAmber,
            accent: .rhythmSage,
            background: .rhythmCream,
            cardBackground: .rhythmCardLight,
            text: .rhythmTextPrimary,
            textSecondary: .rhythmTextSecondary,
            textMuted: .rhythmTextMuted,
            border: Color(white: 0.9),
            success: .rhythmSuccess,
            warning: .rhythmWarning,
            error: .rhythmError
        )
        
        static let dark = Theme(
            primary: .rhythmCoral,
            secondary: .rhythmAmber,
            accent: .rhythmSage,
            background: .rhythmCharcoal,
            cardBackground: .rhythmCardDark,
            text: .white.opacity(0.95),
            textSecondary: Color(white: 0.7),
            textMuted: Color(white: 0.5),
            border: Color(white: 0.3),
            success: .rhythmSuccess,
            warning: .rhythmWarning,
            error: .rhythmError
        )
    }
    
    static func theme(for colorScheme: ColorScheme) -> Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    /// Default theme (light mode) for contexts without ColorScheme
    static var theme: Theme {
        .light
    }
}
