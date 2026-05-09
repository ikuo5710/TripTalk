//
//  Constants.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// アプリ全体の定数
enum Constants {
    /// API関連
    enum API {
        static let realtimeBaseURL = "https://api.openai.com/v1/realtime"
        static let model = "gpt-realtime-translate"
        static let maxReconnectAttempts = 3
    }
    
    /// 音声関連
    enum Audio {
        static let defaultSpeechRate: Double = 1.0
        static let minSpeechRate: Double = 0.5
        static let maxSpeechRate: Double = 2.0
        static let defaultVolume: Double = 1.0
    }
    
    /// UI関連
    enum UI {
        static let translatingTimeout: TimeInterval = 3.0
    }
    
    /// エラーメッセージ
    enum ErrorMessage {
        static let invalidAPIKey = "APIキーを確認してください。"
        static let connectionFailed = "接続できませんでした。通信環境を確認してください。"
        static let reconnectFailed = "再接続できませんでした。もう一度開始してください。"
        static let microphonePermissionRequired = "マイクの許可が必要です。"
        static let audioPlaybackFailed = "音声を再生できませんでした。テキストを確認してください。"
        static let translationFailed = "翻訳できませんでした。もう一度話してください。"
        static let rateLimitExceeded = "利用上限に達した可能性があります。しばらく待ってから再試行してください。"
    }
}
