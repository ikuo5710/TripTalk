//
//  AudioService.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation
import AVFoundation

/// 音声入出力サービス
/// フェーズ5で本格実装予定
final class AudioService {
    static let shared = AudioService()
    
    private init() {}
    
    // MARK: - Properties
    
    private var audioSession: AVAudioSession {
        AVAudioSession.sharedInstance()
    }
    
    var isPlaying: Bool = false
    
    // MARK: - Public Methods
    
    /// 音声セッションを設定
    func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try audioSession.setActive(true)
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
    
    /// マイク入力を開始
    func startRecording() {
        // TODO: フェーズ5で実装
    }
    
    /// マイク入力を停止
    func stopRecording() {
        // TODO: フェーズ5で実装
    }
    
    /// 音声を再生
    func playAudio(data: Data) {
        // TODO: フェーズ5で実装
    }
    
    /// 音声再生を停止
    func stopPlayback() {
        // TODO: フェーズ5で実装
    }
}
