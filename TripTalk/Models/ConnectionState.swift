//
//  ConnectionState.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// 接続状態
enum ConnectionState: Equatable {
    case idle           // 未開始
    case connecting     // 接続中
    case translating    // 翻訳中
    case paused         // 一時停止中
    case reconnecting   // 再接続中
    case error(String)  // エラー
    
    /// 状態の表示テキスト
    var displayText: String {
        switch self {
        case .idle:
            return "未開始"
        case .connecting:
            return "接続中..."
        case .translating:
            return "翻訳中"
        case .paused:
            return "一時停止中"
        case .reconnecting:
            return "再接続中..."
        case .error(let message):
            return message
        }
    }
    
    /// セッションがアクティブかどうか
    var isSessionActive: Bool {
        switch self {
        case .translating, .paused:
            return true
        default:
            return false
        }
    }
    
    /// 翻訳中かどうか
    var isTranslating: Bool {
        self == .translating
    }
}
