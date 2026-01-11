//
//  GentleButton.swift
//  Rhythm
//
//  Invitational button styles - warm, not commanding
//

import SwiftUI

struct GentleButton: View {
    let title: String
    var icon: String?
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case subtle
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .rhythmCoral
            case .secondary: return .rhythmAmber.opacity(0.2)
            case .subtle: return .clear
            case .destructive: return .rhythmError.opacity(0.15)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .rhythmAmber
            case .subtle: return .rhythmTextSecondary
            case .destructive: return .rhythmError
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style.foregroundColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

// MARK: - Icon Button

struct GentleIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var style: GentleButton.ButtonStyle = .secondary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .frame(width: size, height: size)
                .background(style.backgroundColor)
                .foregroundColor(style.foregroundColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - Text Button

struct GentleTextButton: View {
    let title: String
    var icon: String?
    var color: Color = .rhythmCoral
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
        }
    }
}

// MARK: - Snooze Button

struct SnoozeButton: View {
    let option: SnoozeOption
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(option.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(option.gentleLabel)
                    .font(.caption)
                    .foregroundColor(.rhythmTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                isSelected ? Color.rhythmCoral.opacity(0.15) : Color.rhythmChipBackground
            )
            .foregroundColor(isSelected ? .rhythmCoral : .rhythmTextPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.rhythmCoral : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Action Row Button

struct ActionRowButton: View {
    let title: String
    let icon: String
    var subtitle: String?
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .frame(width: 32)
                    .foregroundColor(isDestructive ? .rhythmError : .rhythmCoral)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(isDestructive ? .rhythmError : .rhythmTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.rhythmTextSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.rhythmTextMuted)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.rhythmCardLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        GentleButton(title: "Add to my rhythm", icon: "plus") {}
        
        GentleButton(title: "Later", style: .secondary) {}
        
        GentleButton(title: "Cancel", style: .subtle) {}
        
        GentleButton(title: "Remove", style: .destructive) {}
        
        GentleButton(title: "Loading...", isLoading: true) {}
        
        HStack {
            GentleIconButton(icon: "play.fill", style: .primary) {}
            GentleIconButton(icon: "pause.fill") {}
            GentleIconButton(icon: "checkmark") {}
        }
        
        GentleTextButton(title: "Skip for now", icon: "arrow.right") {}
        
        HStack {
            SnoozeButton(option: .tenMinutes) {}
            SnoozeButton(option: .thirtyMinutes, isSelected: true) {}
        }
        
        ActionRowButton(
            title: "Snooze",
            icon: "clock.arrow.circlepath",
            subtitle: "Find a better time"
        ) {}
    }
    .padding()
}

