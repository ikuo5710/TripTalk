# TripTalk 実装プラン

## 概要

OpenAI Realtime API (gpt-realtime-translate) を使用したリアルタイム翻訳iPhoneアプリのMVP実装プラン。

---

## フェーズ 1: 基盤整備

### 1.1 プロジェクトクリーンアップ
- [ ] SwiftData関連コード削除（Item.swift、ModelContainer設定）
- [ ] ContentView.swiftをシンプルな状態にリセット
- [ ] TripTalkApp.swiftからSwiftData依存を削除

### 1.2 ファイル構成作成
```
TripTalk/
├── App/
│   └── TripTalkApp.swift
├── Views/
│   ├── MainView.swift          # メイン翻訳画面
│   ├── SettingsView.swift      # 設定シート
│   └── Components/
│       ├── LanguagePicker.swift
│       ├── TranslationHistoryView.swift
│       ├── ControlButtons.swift
│       └── StatusIndicator.swift
├── ViewModels/
│   └── TranslationViewModel.swift
├── Models/
│   ├── Language.swift          # 対応言語定義
│   ├── TranslationEntry.swift  # 翻訳エントリ
│   └── ConnectionState.swift   # 接続状態
├── Services/
│   ├── KeychainService.swift   # APIキー管理
│   ├── RealtimeService.swift   # OpenAI Realtime API接続
│   ├── AudioService.swift      # マイク入力・音声出力
│   └── WebRTCClient.swift      # WebRTC実装
└── Utilities/
    └── Constants.swift
```

---

## フェーズ 2: UI実装（SwiftUI）

### 2.1 言語モデル定義
- [ ] Language enum作成（13言語）
- [ ] 言語コード、表示名、OpenAI API用識別子のマッピング

### 2.2 メイン画面レイアウト
- [ ] 入力言語ピッカー
- [ ] 入れ替えボタン（矢印アイコン）
- [ ] 出力言語ピッカー
- [ ] 状態表示エリア
- [ ] 翻訳履歴表示エリア（スクロール可能）
- [ ] コントロールボタン群（開始/一時停止/再開/終了）
- [ ] ツールバー（コピー/共有/設定）

### 2.3 設定シート
- [ ] APIキー入力フィールド
- [ ] APIキー保存/削除ボタン
- [ ] 声質選択（セッション開始前のみ有効）
- [ ] 音声速度スライダー
- [ ] 音量スライダー
- [ ] ミュートトグル

### 2.4 ダークモード対応
- [ ] システムカラー使用
- [ ] Color.primary / Color.secondary活用
- [ ] 背景はColor(.systemBackground)使用

---

## フェーズ 3: Keychain実装

### 3.1 KeychainService
- [ ] APIキー保存機能
- [ ] APIキー取得機能
- [ ] APIキー削除機能
- [ ] Security.framework使用

### 3.2 初回起動フロー
- [ ] APIキー未設定時に設定シート自動表示
- [ ] APIキー設定後にメイン画面有効化

---

## フェーズ 4: WebRTC + OpenAI Realtime API接続

### 4.1 Ephemeral Token取得
- [ ] 保存済みAPIキーでRealtime client secret作成
- [ ] URLSession使用でトークンリクエスト
- [ ] エラーハンドリング

### 4.2 WebRTCClient実装
- [ ] RTCPeerConnection設定
- [ ] SDP Offer/Answer交換
- [ ] ICE Candidate処理
- [ ] DataChannel設定（イベント送受信用）
- [ ] Audio Track設定

### 4.3 RealtimeService実装
- [ ] セッション作成（session.update）
- [ ] 言語設定送信
- [ ] 翻訳モード設定（gpt-realtime-translate）
- [ ] イベントハンドリング
  - [ ] response.audio_transcript.delta（中間テキスト）
  - [ ] response.audio_transcript.done（確定テキスト）
  - [ ] response.audio.delta（音声データ）
  - [ ] error

---

## フェーズ 5: 音声入出力

### 5.1 マイク権限
- [ ] Info.plist にNSMicrophoneUsageDescription追加
- [ ] 権限リクエスト処理
- [ ] 権限拒否時のアラート表示
- [ ] 設定アプリへの誘導

### 5.2 AudioService（入力）
- [ ] AVAudioSession設定（playAndRecord、voiceChat）
- [ ] エコーキャンセル有効化
- [ ] ノイズ抑制有効化
- [ ] 自動ゲイン制御有効化
- [ ] WebRTCへの音声ストリーム接続

### 5.3 AudioService（出力）
- [ ] 翻訳音声の再生
- [ ] 再生中フラグ管理
- [ ] 再生中のマイク入力制御（回り込み防止）
- [ ] 音量・ミュート制御

### 5.4 VAD対応
- [ ] OpenAI Realtime APIのserver_vad使用
- [ ] 発話区切り検出

---

## フェーズ 6: 翻訳テキスト表示

### 6.1 TranslationEntry モデル
- [ ] id（UUID）
- [ ] text（翻訳テキスト）
- [ ] isIntermediate（中間結果フラグ）
- [ ] timestamp

### 6.2 TranslationHistoryView
- [ ] ScrollViewReader使用
- [ ] 新規追加時の自動スクロール
- [ ] 中間結果の表示（薄いスタイル）
- [ ] 確定結果での置換
- [ ] 区切り行表示（言語入れ替え時）

### 6.3 コピー/共有機能
- [ ] 全テキストコピー
- [ ] ShareSheet表示
- [ ] テキストファイル保存

---

## フェーズ 7: 制御機能

### 7.1 開始処理
- [ ] マイク権限確認
- [ ] WebRTC接続開始
- [ ] セッション作成
- [ ] マイク入力開始
- [ ] 状態を「接続中」→「翻訳中」に遷移

### 7.2 一時停止処理
- [ ] マイク入力停止（セッション維持）
- [ ] 翻訳テキスト保持
- [ ] 状態を「一時停止中」に遷移

### 7.3 再開処理
- [ ] マイク入力再開
- [ ] 状態を「翻訳中」に遷移

### 7.4 終了処理
- [ ] マイク入力停止
- [ ] 音声出力停止
- [ ] WebRTCセッション切断
- [ ] 翻訳テキストクリア
- [ ] 状態を「未開始」に遷移

### 7.5 言語入れ替え
- [ ] 入力言語と出力言語のスワップ
- [ ] 現在の翻訳音声停止
- [ ] セッション再作成
- [ ] 区切り行追加
- [ ] 翻訳テキスト保持

---

## フェーズ 8: エラー処理・再接続

### 8.1 エラー表示
- [ ] APIキーエラー
- [ ] 接続エラー
- [ ] マイク権限エラー
- [ ] 音声再生エラー
- [ ] 翻訳エラー
- [ ] 利用上限エラー

### 8.2 自動再接続
- [ ] 最大3回リトライ
- [ ] 「再接続中...」表示
- [ ] 再接続成功時のテキスト保持
- [ ] 再接続失敗時のエラー表示

---

## フェーズ 9: 仕上げ

### 9.1 音声設定UI
- [ ] 声質選択の実装
- [ ] 音声速度調整
- [ ] 音量調整
- [ ] ミュート機能

### 9.2 通信状況対応
- [ ] 翻訳テキスト優先表示
- [ ] 遅延音声のスキップオプション
- [ ] 「翻訳中...」表示（3秒以上遅延時）

### 9.3 最終調整
- [ ] ダークモード確認
- [ ] エラーメッセージ確認
- [ ] UIの使いやすさ確認

---

## 技術的な注意点

### WebRTC
- iOS標準のWebRTCフレームワークは無いため、GoogleのWebRTC.frameworkを使用するか、URLSessionベースのHTTP接続にフォールバック
- CocoaPods/SPMでの導入を検討

### OpenAI Realtime API
- エンドポイント: `wss://api.openai.com/v1/realtime`
- モデル: `gpt-realtime-translate`
- WebRTC使用時はSDPネゴシエーションが必要

### 音声処理
- AVAudioSession categoryは`.playAndRecord`
- modeは`.voiceChat`でエコーキャンセル有効化
- WebRTCのAudioTrackとの連携

---

## 実装順序（推奨）

1. **フェーズ1** → プロジェクト基盤整備
2. **フェーズ2** → UI骨格作成（モック状態で動作確認可能に）
3. **フェーズ3** → Keychain実装（APIキー管理）
4. **フェーズ4** → WebRTC + Realtime API接続（核心部分）
5. **フェーズ5** → 音声入出力
6. **フェーズ6** → 翻訳テキスト表示
7. **フェーズ7** → 制御機能
8. **フェーズ8** → エラー処理
9. **フェーズ9** → 仕上げ

---

## 依存ライブラリ

### 必須
- なし（可能な限り標準フレームワークで実装）

### 検討中
- WebRTC.framework（Google WebRTC）- SPM or CocoaPods
  - 代替案: HTTP-based接続でMVP実装後、WebRTCに移行

---

## ファイル作成順序

```
1. Models/Language.swift
2. Models/ConnectionState.swift
3. Models/TranslationEntry.swift
4. Services/KeychainService.swift
5. Views/Components/LanguagePicker.swift
6. Views/Components/StatusIndicator.swift
7. Views/Components/ControlButtons.swift
8. Views/Components/TranslationHistoryView.swift
9. ViewModels/TranslationViewModel.swift
10. Views/MainView.swift
11. Views/SettingsView.swift
12. Services/AudioService.swift
13. Services/WebRTCClient.swift
14. Services/RealtimeService.swift
15. App/TripTalkApp.swift（更新）
```
