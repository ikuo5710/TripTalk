//
//  TranslationViewModel.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI
import Observation

/// 翻訳画面のViewModel
@MainActor
@Observable
class TranslationViewModel {
    // MARK: - Properties
    
    var inputLanguage: Language = .japanese
    var outputLanguage: Language = .english
    var connectionState: ConnectionState = .idle
    var translationEntries: [TranslationEntry] = []
    
    /// 音声ミュート状態
    var isMuted: Bool = false {
        didSet {
            webRTCClient?.setRemoteAudioMuted(isMuted)
            AudioService.shared.isMuted = isMuted
        }
    }
    
    /// 音声再生中かどうか
    var isPlayingAudio: Bool = false
    
    private var webRTCClient: WebRTCClient?
    private var currentTranscriptId: UUID?
    private var reconnectAttempts = 0
    private var audioPlaybackTimer: Timer?
    
    // MARK: - Computed Properties
    
    /// 全翻訳テキスト（コピー/共有用）
    var allTranslationText: String {
        translationEntries
            .filter { !$0.isSeparator && !$0.isIntermediate }
            .map { $0.text }
            .joined(separator: "\n")
    }
    
    // MARK: - Public Methods
    
    /// APIキーの確認と設定画面の表示
    func checkAPIKeyAndShowSettingsIfNeeded(showSettings: Binding<Bool>) {
        if KeychainService.shared.getAPIKey() == nil {
            showSettings.wrappedValue = true
        }
    }
    
    /// 翻訳開始
    func startTranslation() {
        guard KeychainService.shared.getAPIKey() != nil else {
            connectionState = .error(Constants.ErrorMessage.invalidAPIKey)
            return
        }
        
        connectionState = .connecting
        reconnectAttempts = 0
        
        Task {
            await connectToRealtimeAPI()
        }
    }
    
    /// 一時停止
    func pauseTranslation() {
        guard connectionState.isTranslating else { return }
        connectionState = .paused
        webRTCClient?.pauseAudio()
    }
    
    /// 再開
    func resumeTranslation() {
        guard connectionState == .paused else { return }
        connectionState = .translating
        webRTCClient?.resumeAudio()
    }
    
    /// 終了
    func stopTranslation() {
        audioPlaybackTimer?.invalidate()
        audioPlaybackTimer = nil
        isPlayingAudio = false
        webRTCClient?.disconnect()
        webRTCClient = nil
        connectionState = .idle
        translationEntries.removeAll()
        currentTranscriptId = nil
    }
    
    /// 言語入れ替え
    func swapLanguages() {
        let oldInput = inputLanguage
        let oldOutput = outputLanguage
        
        // セッションがアクティブな場合は区切り行を追加してセッション再作成
        if connectionState.isSessionActive {
            let separator = TranslationEntry.separator(
                from: oldInput,
                to: oldOutput,
                newFrom: oldOutput,
                newTo: oldInput
            )
            translationEntries.append(separator)
            
            // 言語を入れ替え
            inputLanguage = oldOutput
            outputLanguage = oldInput
            
            // セッション再作成
            Task {
                webRTCClient?.disconnect()
                connectionState = .connecting
                await connectToRealtimeAPI()
            }
        } else {
            inputLanguage = oldOutput
            outputLanguage = oldInput
        }
    }
    
    /// 全テキストをコピー
    func copyAllText() {
        UIPasteboard.general.string = allTranslationText
    }
    
    // MARK: - Private Methods
    
    private func connectToRealtimeAPI() async {
        do {
            let client = WebRTCClient()
            client.delegate = self
            self.webRTCClient = client
            
            try await client.connect(outputLanguage: outputLanguage)
            
            connectionState = .translating
            
        } catch {
            print("[TranslationViewModel] Connection error: \(error)")
            handleConnectionError(error)
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        // 再接続を試みる
        if reconnectAttempts < Constants.API.maxReconnectAttempts {
            reconnectAttempts += 1
            connectionState = .reconnecting
            
            Task {
                try? await Task.sleep(for: .seconds(1))
                await connectToRealtimeAPI()
            }
        } else {
            // 再接続失敗
            if let realtimeError = error as? RealtimeService.RealtimeError {
                connectionState = .error(realtimeError.localizedDescription)
            } else if let webrtcError = error as? WebRTCError {
                connectionState = .error(webrtcError.localizedDescription)
            } else {
                connectionState = .error(Constants.ErrorMessage.connectionFailed)
            }
        }
    }
    
    // MARK: - Translation Event Handlers
    
    /// 中間翻訳結果を受信
    private func receiveIntermediateTranslation(_ text: String, id: UUID) {
        if let index = translationEntries.firstIndex(where: { $0.id == id }) {
            translationEntries[index].text = text
        } else {
            let entry = TranslationEntry(id: id, text: text, isIntermediate: true)
            translationEntries.append(entry)
        }
    }
    
    /// 確定翻訳結果を受信
    private func receiveFinalTranslation(_ text: String, id: UUID) {
        if let index = translationEntries.firstIndex(where: { $0.id == id }) {
            translationEntries[index].text = text
            translationEntries[index].isIntermediate = false
        } else {
            let entry = TranslationEntry(id: id, text: text, isIntermediate: false)
            translationEntries.append(entry)
        }
    }
    
    // MARK: - Audio Playback Handling
    
    /// 音声再生終了を処理
    private func handleAudioPlaybackEnded() {
        audioPlaybackTimer?.invalidate()
        audioPlaybackTimer = nil
        isPlayingAudio = false
        webRTCClient?.resumeMicAfterPlayback()
    }
    
    /// 音声再生タイマーをリセット（チャンク受信ごとに呼ばれる）
    private func resetAudioPlaybackTimer() {
        audioPlaybackTimer?.invalidate()
        // 500ms以上音声チャンクが来なければ再生終了と判断
        audioPlaybackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleAudioPlaybackEnded()
            }
        }
    }
}

// MARK: - WebRTCClientDelegate

extension TranslationViewModel: WebRTCClientDelegate {
    nonisolated func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        // 生データの処理（必要に応じて）
    }
    
    nonisolated func webRTCClient(_ client: WebRTCClient, didReceiveEvent event: [String: Any]) {
        Task { @MainActor in
            handleRealtimeEvent(event)
        }
    }
    
    nonisolated func webRTCClientDidConnect(_ client: WebRTCClient) {
        Task { @MainActor in
            connectionState = .translating
            reconnectAttempts = 0
        }
    }
    
    nonisolated func webRTCClientDidDisconnect(_ client: WebRTCClient) {
        Task { @MainActor in
            if connectionState.isSessionActive {
                // 予期せぬ切断 - 再接続を試みる
                handleConnectionError(WebRTCError.connectionFailed)
            }
        }
    }
    
    nonisolated func webRTCClient(_ client: WebRTCClient, didEncounterError error: Error) {
        Task { @MainActor in
            handleConnectionError(error)
        }
    }
    
    // MARK: - Event Handling
    
    private func handleRealtimeEvent(_ event: [String: Any]) {
        guard let type = event["type"] as? String else { return }
        
        switch type {
        case "session.output_transcript.delta":
            // 翻訳テキストの増分
            if let delta = event["delta"] as? String {
                let id = currentTranscriptId ?? UUID()
                if currentTranscriptId == nil {
                    currentTranscriptId = id
                }
                
                // 既存のエントリを更新または新規作成
                if let index = translationEntries.firstIndex(where: { $0.id == id }) {
                    translationEntries[index].text += delta
                } else {
                    receiveIntermediateTranslation(delta, id: id)
                }
            }
            
        case "session.output_transcript.done":
            // 翻訳テキスト確定
            if let id = currentTranscriptId {
                if let index = translationEntries.firstIndex(where: { $0.id == id }) {
                    translationEntries[index].isIntermediate = false
                }
            }
            currentTranscriptId = nil
            
        case "session.input_transcript.delta":
            // 入力テキストの増分（仕様上は表示しない）
            break
            
        case "session.output_audio.started":
            // 翻訳音声再生開始 - マイクを一時停止（回り込み防止）
            isPlayingAudio = true
            webRTCClient?.pauseMicForPlayback()
            
        case "session.output_audio.delta":
            // 翻訳音声のチャンク（WebRTCが自動処理）
            // 再生中フラグを維持
            if !isPlayingAudio {
                isPlayingAudio = true
                webRTCClient?.pauseMicForPlayback()
            }
            // タイマーをリセット（音声チャンクが来たら再生中と判断）
            resetAudioPlaybackTimer()
            
        case "session.output_audio.done":
            // 翻訳音声再生終了 - マイクを再開
            handleAudioPlaybackEnded()
            
        case "error":
            // エラーイベント
            if let errorData = event["error"] as? [String: Any],
               let message = errorData["message"] as? String {
                print("[TranslationViewModel] API Error: \(message)")
                // 致命的なエラーでない場合は表示のみ
            }
            
        default:
            print("[TranslationViewModel] Unknown event type: \(type)")
        }
    }
}
