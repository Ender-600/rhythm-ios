//
//  VoiceButton.swift
//  Rhythm
//
//  Large, thumb-friendly voice input button
//  Supports tap-to-record and press-and-hold
//

import SwiftUI

struct VoiceButton: View {
    @Binding var isRecording: Bool
    var duration: TimeInterval = 0
    var hasPermission: Bool = true
    var onTap: () -> Void
    var onLongPressStart: () -> Void
    var onLongPressEnd: () -> Void
    
    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0
    
    private let buttonSize: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Pulsing background when recording
            if isRecording {
                Circle()
                    .fill(Color.rhythmRecording.opacity(0.3))
                    .frame(width: buttonSize * 1.5, height: buttonSize * 1.5)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                        }
                    }
                    .onDisappear {
                        pulseScale = 1.0
                    }
            }
            
            // Main button
            Circle()
                .fill(
                    isRecording
                        ? LinearGradient(colors: [.rhythmRecording, .rhythmCoral], startPoint: .top, endPoint: .bottom)
                        : LinearGradient.rhythmVoice
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(color: .rhythmCoral.opacity(0.3), radius: isPressed ? 5 : 10, y: isPressed ? 2 : 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
            // Icon
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .symbolEffect(.variableColor.iterative, isActive: isRecording)
            
            // Duration indicator
            if isRecording {
                Text(formatDuration(duration))
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white.opacity(0.8))
                    .offset(y: 30)
            }
        }
        .opacity(hasPermission ? 1 : 0.5)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        withAnimation(.easeInOut(duration: 0.1)) {
                            // Visual feedback
                        }
                        // Start long press timer
                        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.pressAndHoldThreshold) {
                            if isPressed && !isRecording {
                                onLongPressStart()
                            }
                        }
                    }
                }
                .onEnded { _ in
                    let wasLongPress = isRecording
                    isPressed = false
                    
                    if wasLongPress {
                        onLongPressEnd()
                    } else {
                        onTap()
                    }
                }
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Voice Button Container

struct VoiceButtonContainer: View {
    let viewModel: QuickAddViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            VoiceButton(
                isRecording: Binding(
                    get: { viewModel.isRecording },
                    set: { _ in }
                ),
                duration: viewModel.recordingDuration,
                hasPermission: viewModel.hasVoicePermission,
                onTap: {
                    Task {
                        if viewModel.isRecording {
                            await viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                },
                onLongPressStart: {
                    Task {
                        await viewModel.startRecording()
                    }
                },
                onLongPressEnd: {
                    Task {
                        await viewModel.stopRecording()
                    }
                }
            )
            
            Text(viewModel.isRecording ? Copy.QuickAdd.voiceRecording : Copy.QuickAdd.voiceHint)
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
        }
    }
}

// MARK: - Mini Voice Button (for inline use)

struct MiniVoiceButton: View {
    var isRecording: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isRecording ? Color.rhythmRecording : Color.rhythmCoral)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        VoiceButton(
            isRecording: .constant(false),
            onTap: {},
            onLongPressStart: {},
            onLongPressEnd: {}
        )
        
        VoiceButton(
            isRecording: .constant(true),
            duration: 5.5,
            onTap: {},
            onLongPressStart: {},
            onLongPressEnd: {}
        )
        
        MiniVoiceButton(onTap: {})
    }
    .padding()
    .background(Color.rhythmCream)
}

