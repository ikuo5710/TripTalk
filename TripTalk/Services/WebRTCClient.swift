//
//  WebRTCClient.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation
import WebRTC
import AVFoundation

/// WebRTCクライアント - OpenAI Realtime Translation APIとの接続を管理
final class WebRTCClient: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: WebRTCClientDelegate?
    
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteAudioTrack: RTCAudioTrack?
    
    private let factory: RTCPeerConnectionFactory
    private let audioSession = AVAudioSession.sharedInstance()
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    
    private(set) var isConnected = false
    private var clientSecret: String?
    
    /// 音声再生中のマイク一時停止フラグ
    private var isMicPausedForPlayback = false
    
    /// ユーザーによる手動一時停止フラグ
    private var isUserPaused = false
    
    // MARK: - Initialization
    
    override init() {
        // WebRTC初期化
        RTCInitializeSSL()
        
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory(
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory
        )
        
        super.init()
    }
    
    deinit {
        disconnect()
        RTCCleanupSSL()
    }
    
    // MARK: - Public Methods
    
    /// 翻訳セッションに接続
    /// - Parameter outputLanguage: 出力言語
    func connect(outputLanguage: Language) async throws {
        // 1. クライアントシークレットを取得
        let secret = try await RealtimeService.shared.getClientSecret(outputLanguage: outputLanguage.apiCode)
        self.clientSecret = secret
        
        // 2. オーディオセッションを設定
        try configureAudioSession()
        
        // 3. PeerConnectionを作成
        try createPeerConnection()
        
        // 4. データチャネルを作成
        createDataChannel()
        
        // 5. ローカルオーディオトラックを追加
        addLocalAudioTrack()
        
        // 6. SDPオファーを作成して送信
        try await negotiateConnection(clientSecret: secret)
        
        isConnected = true
        
        await MainActor.run {
            delegate?.webRTCClientDidConnect(self)
        }
    }
    
    /// 接続を切断
    func disconnect() {
        dataChannel?.close()
        dataChannel = nil
        
        peerConnection?.close()
        peerConnection = nil
        
        localAudioTrack = nil
        remoteAudioTrack = nil
        
        isConnected = false
        clientSecret = nil
        
        delegate?.webRTCClientDidDisconnect(self)
    }
    
    /// マイク入力を一時停止（ユーザー操作）
    func pauseAudio() {
        isUserPaused = true
        localAudioTrack?.isEnabled = false
    }
    
    /// マイク入力を再開（ユーザー操作）
    func resumeAudio() {
        isUserPaused = false
        // 再生中でなければマイクを有効化
        if !isMicPausedForPlayback {
            localAudioTrack?.isEnabled = true
        }
    }
    
    /// 音声再生開始時のマイク一時停止（回り込み防止）
    func pauseMicForPlayback() {
        guard !isMicPausedForPlayback else { return }
        isMicPausedForPlayback = true
        localAudioTrack?.isEnabled = false
        AudioService.shared.notifyRemoteAudioStarted()
    }
    
    /// 音声再生終了時のマイク再開（回り込み防止）
    func resumeMicAfterPlayback() {
        guard isMicPausedForPlayback else { return }
        isMicPausedForPlayback = false
        AudioService.shared.notifyRemoteAudioStopped()
        // ユーザーが手動で一時停止していなければマイクを有効化
        if !isUserPaused {
            localAudioTrack?.isEnabled = true
        }
    }
    
    /// リモート音声のミュート状態を設定
    func setRemoteAudioMuted(_ muted: Bool) {
        remoteAudioTrack?.isEnabled = !muted
    }
    
    /// リモート音声が有効かどうか
    var isRemoteAudioEnabled: Bool {
        remoteAudioTrack?.isEnabled ?? false
    }
    
    // MARK: - Private Methods
    
    private func configureAudioSession() throws {
        // RTCAudioSessionを使用してWebRTCの音声設定を行う
        rtcAudioSession.lockForConfiguration()
        defer { rtcAudioSession.unlockForConfiguration() }
        
        // RTCAudioSessionの設定（useManualAudioをfalseにして自動管理）
        rtcAudioSession.useManualAudio = false
        rtcAudioSession.isAudioEnabled = true
        
        // AVAudioSessionで設定
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try audioSession.overrideOutputAudioPort(.speaker)
        try audioSession.setActive(true)
        
        // 出力音量を確認（デバッグ用）
        print("[WebRTC] Output volume: \(audioSession.outputVolume)")
        print("[WebRTC] Current route: \(audioSession.currentRoute.outputs)")
    }
    
    private func createPeerConnection() throws {
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        // ICEサーバーは不要（OpenAIが処理）
        config.iceServers = []
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )
        
        guard let pc = factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        ) else {
            throw WebRTCError.failedToCreatePeerConnection
        }
        
        self.peerConnection = pc
    }
    
    private func createDataChannel() {
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        
        dataChannel = peerConnection?.dataChannel(forLabel: "oai-events", configuration: config)
        dataChannel?.delegate = self
    }
    
    private func addLocalAudioTrack() {
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: [
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "googNoiseSuppression": "true",
                "googHighpassFilter": "true"
            ]
        )
        
        let audioSource = factory.audioSource(with: audioConstraints)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        
        peerConnection?.add(audioTrack, streamIds: ["stream0"])
        self.localAudioTrack = audioTrack
    }
    
    private func negotiateConnection(clientSecret: String) async throws {
        guard let pc = peerConnection else {
            throw WebRTCError.noPeerConnection
        }
        
        // SDPオファーを作成
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )
        
        let offer = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<RTCSessionDescription, Error>) in
            pc.offer(for: constraints) { sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(throwing: WebRTCError.failedToCreateOffer)
                }
            }
        }
        
        // ローカルディスクリプションを設定
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pc.setLocalDescription(offer) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // SDPをOpenAIに送信してアンサーを取得
        let answerSDP = try await RealtimeService.shared.sendSDPOffer(
            sdpOffer: offer.sdp,
            clientSecret: clientSecret
        )
        
        // リモートディスクリプションを設定
        let answer = RTCSessionDescription(type: .answer, sdp: answerSDP)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pc.setRemoteDescription(answer) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - RTCPeerConnectionDelegate

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("[WebRTC] Signaling state: \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("[WebRTC] Stream added")
        if let audioTrack = stream.audioTracks.first {
            self.remoteAudioTrack = audioTrack
            audioTrack.isEnabled = true
            
            // リモートオーディオの音量を最大に設定
            DispatchQueue.main.async {
                self.configureAudioForPlayback()
            }
        }
    }
    
    /// リモートオーディオ再生用の設定
    private func configureAudioForPlayback() {
        do {
            // スピーカー出力を強制
            try audioSession.overrideOutputAudioPort(.speaker)
            print("[WebRTC] Audio output set to speaker")
        } catch {
            print("[WebRTC] Failed to override audio port: \(error)")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("[WebRTC] Stream removed")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("[WebRTC] Should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("[WebRTC] ICE connection state: \(newState.rawValue)")
        
        switch newState {
        case .connected, .completed:
            break
        case .disconnected, .failed, .closed:
            if isConnected {
                isConnected = false
                delegate?.webRTCClientDidDisconnect(self)
            }
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("[WebRTC] ICE gathering state: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // OpenAI Realtime APIではICE candidateの送信は不要
        print("[WebRTC] ICE candidate generated")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("[WebRTC] ICE candidates removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("[WebRTC] Data channel opened: \(dataChannel.label)")
        self.dataChannel = dataChannel
        dataChannel.delegate = self
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("[WebRTC] Data channel state: \(dataChannel.readyState.rawValue)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        let data = buffer.data
        
        // JSONイベントをパース
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            delegate?.webRTCClient(self, didReceiveEvent: json)
        } else {
            delegate?.webRTCClient(self, didReceiveData: data)
        }
    }
}

// MARK: - WebRTCClientDelegate

protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, didReceiveEvent event: [String: Any])
    func webRTCClientDidConnect(_ client: WebRTCClient)
    func webRTCClientDidDisconnect(_ client: WebRTCClient)
    func webRTCClient(_ client: WebRTCClient, didEncounterError error: Error)
}

// MARK: - WebRTCError

enum WebRTCError: Error, LocalizedError {
    case failedToCreatePeerConnection
    case noPeerConnection
    case failedToCreateOffer
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .failedToCreatePeerConnection:
            return "PeerConnectionの作成に失敗しました"
        case .noPeerConnection:
            return "PeerConnectionが存在しません"
        case .failedToCreateOffer:
            return "SDPオファーの作成に失敗しました"
        case .connectionFailed:
            return Constants.ErrorMessage.connectionFailed
        }
    }
}
