//
//  TranslationViewModel.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI
import Observation
import AVFoundation

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
    
    /// マイク権限が必要なダイアログを表示
    var showMicrophonePermissionAlert: Bool = false
    
    /// コピー完了通知を表示
    var showCopyConfirmation: Bool = false
    
    private var webRTCClient: WebRTCClient?
    private var currentTranscriptId: UUID?
    private var reconnectAttempts = 0
    private var audioPlaybackTimer: Timer?
    private var backgroundObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init() {
        setupBackgroundObserver()
    }
    
    deinit {
        // Note: backgroundObserverはMainActorで管理されるため、
        // NotificationCenterが自動的にクリーンアップを行う
    }
    
    private func setupBackgroundObserver() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: .appDidEnterBackground,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
    }
    
    private func handleAppDidEnterBackground() {
        // バックグラウンドに移行したらマイク入力を停止
        // セッションは維持するが、音声送信は停止
        if connectionState.isSessionActive {
            webRTCClient?.pauseAudio()
            // 状態は変更しない（フォアグラウンド復帰時に自動再開しないため）
        }
    }
    
    // MARK: - Computed Properties
    
    /// 全翻訳テキスト（コピー/共有用）
    /// 区切り行の位置では空行を入れ、中間結果も含める（翻訳中でもコピー可能）
    var allTranslationText: String {
        var result: [String] = []
        for entry in translationEntries {
            if entry.isSeparator {
                // 区切り行の位置で空行を追加
                result.append("")
            } else {
                result.append(entry.text)
            }
        }
        return result.joined(separator: "\n")
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
        
        // マイク権限をチェック
        Task {
            await checkMicrophonePermissionAndStart()
        }
    }
    
    /// マイク権限をチェックして翻訳開始
    private func checkMicrophonePermissionAndStart() async {
        let permission = AudioService.shared.checkMicrophonePermission()
        
        switch permission {
        case .undetermined:
            // 権限をリクエスト
            let granted = await AudioService.shared.requestMicrophonePermission()
            if granted {
                await startTranslationSession()
            } else {
                showMicrophonePermissionAlert = true
            }
            
        case .denied:
            // 権限が拒否されている
            showMicrophonePermissionAlert = true
            
        case .granted:
            // 権限あり - 翻訳開始
            await startTranslationSession()
            
        @unknown default:
            showMicrophonePermissionAlert = true
        }
    }
    
    /// 翻訳セッションを開始
    private func startTranslationSession() async {
        connectionState = .connecting
        reconnectAttempts = 0
        await connectToRealtimeAPI()
    }
    
    /// 設定アプリを開く
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
        
        // delegateをクリアして切断（コールバックを防ぐ）
        webRTCClient?.delegate = nil
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
                // 古いクライアントのdelegateをクリアして切断（コールバックを防ぐ）
                webRTCClient?.delegate = nil
                webRTCClient?.disconnect()
                webRTCClient = nil
                
                // 現在のトランスクリプトIDをリセット（新しい翻訳は新しいエントリに）
                currentTranscriptId = nil
                
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
        
        // コピー完了通知を表示
        showCopyConfirmation = true
        
        // 2秒後に通知を非表示
        Task {
            try? await Task.sleep(for: .seconds(2))
            showCopyConfirmation = false
        }
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
        // APIキーエラーやレート制限は再接続しない
        if let realtimeError = error as? RealtimeService.RealtimeError {
            switch realtimeError {
            case .noAPIKey:
                connectionState = .error(Constants.ErrorMessage.invalidAPIKey)
                return
            case .httpError(let code, _):
                if code == 401 {
                    connectionState = .error(Constants.ErrorMessage.invalidAPIKey)
                    return
                } else if code == 429 {
                    connectionState = .error(Constants.ErrorMessage.rateLimitExceeded)
                    return
                }
            default:
                break
            }
        }
        
        // 再接続を試みる
        if reconnectAttempts < Constants.API.maxReconnectAttempts {
            reconnectAttempts += 1
            connectionState = .reconnecting
            
            // 指数バックオフで再接続
            let delay = Double(reconnectAttempts) * 1.5
            Task {
                try? await Task.sleep(for: .seconds(delay))
                await connectToRealtimeAPI()
            }
        } else {
            // 再接続失敗
            connectionState = .error(Constants.ErrorMessage.reconnectFailed)
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
            if let errorData = event["error"] as? [String: Any] {
                let message = errorData["message"] as? String ?? "不明なエラー"
                let code = errorData["code"] as? String ?? ""
                
                print("[TranslationViewModel] API Error: \(code) - \(message)")
                
                // エラーコードに基づいて処理
                switch code {
                case "rate_limit_exceeded":
                    connectionState = .error(Constants.ErrorMessage.rateLimitExceeded)
                case "invalid_api_key", "authentication_error":
                    connectionState = .error(Constants.ErrorMessage.invalidAPIKey)
                case "server_error":
                    // サーバーエラーは再接続を試みる
                    handleConnectionError(WebRTCError.connectionFailed)
                default:
                    // 一時的なエラーは表示のみ、セッションは維持
                    print("[TranslationViewModel] Non-fatal error: \(message)")
                }
            }
            
        default:
            print("[TranslationViewModel] Unknown event type: \(type)")
        }
    }
}
