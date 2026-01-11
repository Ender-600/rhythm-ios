//
//  OfflineBanner.swift
//  Rhythm
//
//  Network status indicator - friendly, not alarming
//

import SwiftUI

struct OfflineBanner: View {
    var isVisible: Bool = true
    var message: String = Copy.EmptyState.offlineMessage
    
    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)
                
                Text(message)
                    .font(.subheadline)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.rhythmAmber.opacity(0.15))
            .foregroundColor(.rhythmAmber)
        }
    }
}

// MARK: - Sync Status Badge

struct SyncStatusBadge: View {
    var isSyncing: Bool = false
    var pendingCount: Int = 0
    var lastSyncTime: Date?
    
    var body: some View {
        HStack(spacing: 6) {
            if isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Syncing...")
            } else if pendingCount > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("\(pendingCount) pending")
            } else if let lastSync = lastSyncTime {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.rhythmSuccess)
                Text("Synced \(lastSync.relativeDescription)")
            } else {
                Image(systemName: "checkmark.circle")
                Text("Up to date")
            }
        }
        .font(.caption)
        .foregroundColor(.rhythmTextSecondary)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.rhythmTextMuted)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.rhythmTextPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.rhythmTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let action = buttonAction {
                GentleButton(title: buttonTitle, action: action)
                    .frame(width: 200)
            }
        }
        .padding(40)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.rhythmTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    var retryAction: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.title3)
            
            Text(message)
                .font(.subheadline)
            
            Spacer()
            
            if let retry = retryAction {
                Button("Retry", action: retry)
                    .font(.subheadline.weight(.medium))
            }
            
            if let dismiss = dismissAction {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.rhythmError.opacity(0.1))
        .foregroundColor(.rhythmError)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        OfflineBanner()
        
        SyncStatusBadge(isSyncing: true)
        SyncStatusBadge(pendingCount: 3)
        SyncStatusBadge(lastSyncTime: Date().addingTimeInterval(-300))
        
        EmptyStateView(
            icon: "tray",
            title: Copy.EmptyState.noTasksTitle,
            message: Copy.EmptyState.noTasksMessage,
            buttonTitle: Copy.EmptyState.noTasksButton
        ) {}
        
        ErrorBanner(
            message: "Something went wrong",
            retryAction: {},
            dismissAction: {}
        )
        .padding()
    }
}

