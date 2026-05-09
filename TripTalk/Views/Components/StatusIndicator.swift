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
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 8) {
            // ステータスドット
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                // 接続中・再接続中のパルスアニメーション
                if state == .connecting || state == .reconnecting {
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 18, height: 18)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }
                
                // 翻訳中のパルスアニメーション
                if state == .translating {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
            }
            .frame(width: 20, height: 20)
            
            // ステータステキスト
            if case .error(let message) = state {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            } else {
                Text(state.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(textColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(20)
        .onAppear {
            isPulsing = true
        }
        .onChange(of: state) { _, _ in
            isPulsing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPulsing = true
            }
        }
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
        switch state {
        case .error:
            return Color.red.opacity(0.1)
        default:
            return Color(.secondarySystemBackground)
        }
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
