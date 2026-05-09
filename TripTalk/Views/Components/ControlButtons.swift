//
//  ControlButtons.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

/// コントロールボタン群
struct ControlButtons: View {
    let connectionState: ConnectionState
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            switch connectionState {
            case .idle, .error:
                startButton
                
            case .connecting, .reconnecting:
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(width: 80, height: 80)
                
            case .translating:
                pauseButton
                stopButton
                
            case .paused:
                resumeButton
                stopButton
            }
        }
        .animation(.easeInOut(duration: 0.2), value: connectionState)
    }
    
    private var startButton: some View {
        Button(action: onStart) {
            VStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 28))
                Text("開始")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 88, height: 88)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var pauseButton: some View {
        Button(action: onPause) {
            VStack(spacing: 4) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 22))
                Text("一時停止")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(width: 72, height: 72)
            .background(Color.orange)
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    private var resumeButton: some View {
        Button(action: onResume) {
            VStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 22))
                Text("再開")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(width: 72, height: 72)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(color: .green.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    private var stopButton: some View {
        Button(action: onStop) {
            VStack(spacing: 4) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 22))
                Text("終了")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(width: 72, height: 72)
            .background(Color.red)
            .foregroundStyle(.white)
            .clipShape(Circle())
            .shadow(color: .red.opacity(0.3), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 40) {
        ControlButtons(
            connectionState: .idle,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        ControlButtons(
            connectionState: .connecting,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        ControlButtons(
            connectionState: .translating,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        ControlButtons(
            connectionState: .paused,
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
    }
    .padding()
}
