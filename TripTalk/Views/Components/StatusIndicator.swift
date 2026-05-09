//
//  StatusIndicator.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

/// 状態表示インジケーター
struct StatusIndicator: View {
    let state: ConnectionState
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay {
                    if state == .connecting || state == .reconnecting {
                        Circle()
                            .stroke(statusColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 16, height: 16)
                    }
                }
            
            Text(state.displayText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(20)
    }
    
    private var statusColor: Color {
        switch state {
        case .idle:
            return .gray
        case .connecting, .reconnecting:
            return .orange
        case .translating:
            return .green
        case .paused:
            return .yellow
        case .error:
            return .red
        }
    }
    
    private var textColor: Color {
        switch state {
        case .error:
            return .red
        default:
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        Color(.secondarySystemBackground)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusIndicator(state: .idle)
        StatusIndicator(state: .connecting)
        StatusIndicator(state: .translating)
        StatusIndicator(state: .paused)
        StatusIndicator(state: .reconnecting)
        StatusIndicator(state: .error("接続できませんでした"))
    }
    .padding()
}
