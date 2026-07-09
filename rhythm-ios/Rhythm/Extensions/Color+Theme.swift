//
//  Color+Theme.swift
//  Rhythm
//
//  Quiet Swiss design system: precise, calm, and never commanding.
//

import SwiftUI
import UIKit

extension Color {
    // MARK: - Quiet Swiss Core Palette

    /// Near-black ink for typography, rules, and primary controls.
    static let rhythmInk = Color(red: 0.065, green: 0.063, blue: 0.055)

    /// Warm paper instead of digital white.
    static let rhythmPaper = Color(red: 0.972, green: 0.965, blue: 0.925)

    /// Vermilion signal color. Used sparingly for the current action.
    static let rhythmSignal = Color(red: 0.83, green: 0.12, blue: 0.065)

    /// Functional green for completion and low-pressure confirmation.
    static let rhythmGreen = Color(red: 0.18, green: 0.39, blue: 0.27)

    /// Ochre for caution and time-related secondary information.
    static let rhythmOchre = Color(red: 0.67, green: 0.46, blue: 0.10)
    
    // Legacy semantic names retained so business-facing views do not need to
    // know that the visual system changed.
    static let rhythmCoral = rhythmSignal
    
    static let rhythmAmber = rhythmOchre
    
    static let rhythmSage = rhythmGreen
    
    static let rhythmPlum = rhythmInk
    
    // MARK: - Background Colors
    
    static let rhythmCream = rhythmPaper
    
    static let rhythmCharcoal = Color(red: 0.075, green: 0.073, blue: 0.067)
    
    static let rhythmCardLight = Color(red: 0.99, green: 0.985, blue: 0.95)
    static let rhythmCardDark = Color(red: 0.115, green: 0.112, blue: 0.102)
    
    // MARK: - Text Colors
    
    static let rhythmTextPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.95, alpha: 1)
            : UIColor(red: 0.065, green: 0.063, blue: 0.055, alpha: 1)
    })
    
    static let rhythmTextSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.70, alpha: 1)
            : UIColor(red: 0.37, green: 0.365, blue: 0.34, alpha: 1)
    })
    
    static let rhythmTextMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.50, alpha: 1)
            : UIColor(red: 0.58, green: 0.57, blue: 0.53, alpha: 1)
    })
    
    // MARK: - Semantic Colors
    
    static let rhythmSuccess = rhythmGreen
    
    static let rhythmWarning = rhythmOchre
    
    static let rhythmError = Color(red: 0.70, green: 0.10, blue: 0.075)
    
    // MARK: - Voice Button
    
    static let rhythmRecording = rhythmSignal
    
    static let rhythmVoiceIdle = rhythmSignal
    
    // MARK: - Chip Colors
    
    static let rhythmChipBackground = Color(red: 0.91, green: 0.90, blue: 0.85)
    static let rhythmChipBackgroundDark = Color(red: 0.16, green: 0.155, blue: 0.145)

    static let rhythmRuleLight = Color.black.opacity(0.18)
    static let rhythmRuleDark = Color.white.opacity(0.22)
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

    static func rhythmRule(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .rhythmRuleDark : .rhythmRuleLight
    }
}

// MARK: - Gradient Presets

extension LinearGradient {
    /// Legacy presets intentionally remain nearly flat in the Swiss system.
    static let rhythmSunrise = LinearGradient(
        colors: [.rhythmSignal, .rhythmSignal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Calm evening gradient
    static let rhythmEvening = LinearGradient(
        colors: [.rhythmInk, .rhythmInk],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Voice button gradient
    static let rhythmVoice = LinearGradient(
        colors: [.rhythmSignal, .rhythmSignal],
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
            border: .rhythmRuleLight,
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
            border: .rhythmRuleDark,
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
