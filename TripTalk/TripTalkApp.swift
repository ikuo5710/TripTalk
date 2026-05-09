//
//  TripTalkApp.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

@main
struct TripTalkApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // アプリがアクティブになった
            print("[TripTalkApp] App became active")
            
        case .inactive:
            // アプリが非アクティブになった
            print("[TripTalkApp] App became inactive")
            
        case .background:
            // アプリがバックグラウンドに移行
            // MVPではバックグラウンド翻訳非対応
            print("[TripTalkApp] App entered background")
            NotificationCenter.default.post(name: .appDidEnterBackground, object: nil)
            
        @unknown default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appDidEnterBackground = Notification.Name("appDidEnterBackground")
}
