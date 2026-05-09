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
        
        // TODO: フェーズ4で実際のWebRTC接続とマイク入力開始を実装
        // 仮実装：接続完了をシミュレート
        Task {
            try? await Task.sleep(for: .seconds(1))
            connectionState = .translating
        }
    }
    
    /// 一時停止
    func pauseTranslation() {
        guard connectionState.isTranslating else { return }
        connectionState = .paused
        // TODO: フェーズ5でマイク入力を停止（セッションは維持）
    }
    
    /// 再開
    func resumeTranslation() {
        guard connectionState == .paused else { return }
        connectionState = .translating
        // TODO: フェーズ5でマイク入力を再開
    }
    
    /// 終了
    func stopTranslation() {
        connectionState = .idle
        translationEntries.removeAll()
        // TODO: フェーズ4/5でWebRTCセッション切断、マイク・音声停止
    }
    
    /// 言語入れ替え
    func swapLanguages() {
        let oldInput = inputLanguage
        let oldOutput = outputLanguage
        
        // セッションがアクティブな場合は区切り行を追加
        if connectionState.isSessionActive {
            let separator = TranslationEntry.separator(
                from: oldInput,
                to: oldOutput,
                newFrom: oldOutput,
                newTo: oldInput
            )
            translationEntries.append(separator)
            
            // TODO: フェーズ4でセッション再作成
        }
        
        inputLanguage = oldOutput
        outputLanguage = oldInput
    }
    
    /// 全テキストをコピー
    func copyAllText() {
        UIPasteboard.general.string = allTranslationText
    }
    
    // MARK: - Translation Event Handlers (フェーズ4以降で使用)
    
    /// 中間翻訳結果を受信
    func receiveIntermediateTranslation(_ text: String, id: UUID) {
        if let index = translationEntries.firstIndex(where: { $0.id == id }) {
            translationEntries[index].text = text
        } else {
            let entry = TranslationEntry(id: id, text: text, isIntermediate: true)
            translationEntries.append(entry)
        }
    }
    
    /// 確定翻訳結果を受信
    func receiveFinalTranslation(_ text: String, id: UUID) {
        if let index = translationEntries.firstIndex(where: { $0.id == id }) {
            translationEntries[index].text = text
            translationEntries[index].isIntermediate = false
        } else {
            let entry = TranslationEntry(id: id, text: text, isIntermediate: false)
            translationEntries.append(entry)
        }
    }
}
