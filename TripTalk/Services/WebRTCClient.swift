//
//  WebRTCClient.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// WebRTCクライアント
/// フェーズ4で本格実装予定
final class WebRTCClient {
    
    // MARK: - Delegate Protocol
    
    weak var delegate: WebRTCClientDelegate?
    
    // MARK: - Properties
    
    private var isConnected = false
    
    // MARK: - Public Methods
    
    /// 接続を開始
    func connect(token: String) async throws {
        // TODO: フェーズ4で実装
        // - RTCPeerConnection設定
        // - SDP Offer/Answer交換
        // - ICE Candidate処理
        // - DataChannel設定
        // - Audio Track設定
    }
    
    /// 接続を切断
    func disconnect() {
        // TODO: フェーズ4で実装
        isConnected = false
    }
    
    /// データを送信
    func send(data: Data) {
        // TODO: フェーズ4で実装
    }
    
    /// イベントを送信
    func sendEvent(_ event: [String: Any]) {
        // TODO: フェーズ4で実装
    }
}

/// WebRTCクライアントのデリゲート
protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didReceiveEvent event: [String: Any])
    func webRTCClientDidConnect(_ client: WebRTCClient)
    func webRTCClientDidDisconnect(_ client: WebRTCClient)
    func webRTCClient(_ client: WebRTCClient, didEncounterError error: Error)
}
