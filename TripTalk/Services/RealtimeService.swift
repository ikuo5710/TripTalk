//
//  RealtimeService.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// OpenAI Realtime API接続サービス
/// フェーズ4で本格実装予定
final class RealtimeService {
    static let shared = RealtimeService()
    
    private init() {}
    
    // MARK: - Properties
    
    private let baseURL = Constants.API.realtimeBaseURL
    private let model = Constants.API.model
    
    // MARK: - Public Methods
    
    /// Ephemeral Tokenを取得
    func getEphemeralToken() async throws -> String {
        // TODO: フェーズ4で実装
        fatalError("Not implemented")
    }
    
    /// セッションを開始
    func startSession(inputLanguage: String, outputLanguage: String) async throws {
        // TODO: フェーズ4で実装
    }
    
    /// セッションを終了
    func endSession() {
        // TODO: フェーズ4で実装
    }
}
