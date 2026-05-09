//
//  AudioService.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation
import AVFoundation

/// 音声入出力サービス
final class AudioService {
    static let shared = AudioService()
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Properties
    
    private var audioSession: AVAudioSession {
        AVAudioSession.sharedInstance()
    }
    
    /// 音声再生中かどうか（回り込み防止用）
    private(set) var isPlayingRemoteAudio = false
    
    /// 音声再生状態変更時のコールバック
    var onPlaybackStateChanged: ((Bool) -> Void)?
    
    /// 音声設定
    var playbackSpeed: Float = 1.0
    var volume: Float = 1.0
    var isMuted: Bool = false
    
    // MARK: - Setup
    
    private func setupNotifications() {
        // 音声出力ルート変更の監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        // 音声中断の監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// 音声セッションを設定（通話・翻訳向け）
    func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .allowBluetoothA2DP,
                .mixWithOthers
            ]
        )
        
        // 低遅延設定
        try audioSession.setPreferredIOBufferDuration(0.005)
        try audioSession.setPreferredSampleRate(24000)
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    /// マイク権限をリクエスト
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// マイク権限の状態を確認
    func checkMicrophonePermission() -> AVAudioApplication.recordPermission {
        AVAudioApplication.shared.recordPermission
    }
    
    /// リモート音声再生開始を通知（マイク一時停止トリガー）
    func notifyRemoteAudioStarted() {
        guard !isPlayingRemoteAudio else { return }
        isPlayingRemoteAudio = true
        onPlaybackStateChanged?(true)
    }
    
    /// リモート音声再生終了を通知（マイク再開トリガー）
    func notifyRemoteAudioStopped() {
        guard isPlayingRemoteAudio else { return }
        isPlayingRemoteAudio = false
        onPlaybackStateChanged?(false)
    }
    
    /// 現在の音声出力先を取得
    func getCurrentOutputRoute() -> String {
        let route = audioSession.currentRoute
        if let output = route.outputs.first {
            switch output.portType {
            case .builtInSpeaker:
                return "スピーカー"
            case .headphones:
                return "ヘッドフォン"
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                return output.portName
            default:
                return output.portName
            }
        }
        return "不明"
    }
    
    // MARK: - Private Methods
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("[AudioService] Route changed: \(reason)")
        
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            // デバイス接続・切断時は自動で対応
            break
        default:
            break
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("[AudioService] Audio session interrupted")
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? audioSession.setActive(true)
                }
            }
        @unknown default:
            break
        }
    }
}
