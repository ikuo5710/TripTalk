//
//  SettingsView.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

/// 設定画面
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var savedAPIKey: String = ""
    @AppStorage("selectedVoice") private var selectedVoice: VoiceType = .alloy
    @AppStorage("speechRate") private var speechRate: Double = 1.0
    @AppStorage("volume") private var volume: Double = 1.0
    @AppStorage("isMuted") private var isMuted: Bool = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                voiceSection
                speechRateSection
                volumeSection
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("APIキーを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteAPIKey()
                }
            } message: {
                Text("APIキーを削除すると、再度入力が必要になります。")
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    // MARK: - Sections
    
    private var apiKeySection: some View {
        Section {
            if savedAPIKey.isEmpty {
                SecureField("APIキーを入力", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                
                Button("保存") {
                    saveAPIKey()
                }
                .disabled(apiKey.isEmpty)
            } else {
                HStack {
                    Text("APIキー")
                    Spacer()
                    Text("設定済み")
                        .foregroundStyle(.secondary)
                }
                
                Button("APIキーを削除", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        } header: {
            Text("OpenAI API")
        } footer: {
            Text("APIキーはデバイス内に安全に保存されます")
        }
    }
    
    private var voiceSection: some View {
        Section {
            Picker("声質", selection: $selectedVoice) {
                ForEach(VoiceType.allCases) { voice in
                    Text(voice.displayName).tag(voice)
                }
            }
        } header: {
            Text("音声設定")
        } footer: {
            Text("声質は翻訳開始前のみ変更できます")
        }
    }
    
    private var speechRateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("音声速度")
                    Spacer()
                    Text("\(String(format: "%.1f", speechRate))x")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $speechRate, in: 0.5...2.0, step: 0.1) {
                    Text("音声速度")
                } minimumValueLabel: {
                    Text("0.5x")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("2.0x")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var volumeSection: some View {
        Section {
            Toggle("ミュート", isOn: $isMuted)
            
            if !isMuted {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("音量")
                        Spacer()
                        Text("\(Int(volume * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $volume, in: 0...1, step: 0.1) {
                        Text("音量")
                    } minimumValueLabel: {
                        Image(systemName: "speaker.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadSettings() {
        // Keychainのみをチェック（.envは含まない）
        savedAPIKey = KeychainService.shared.getAPIKeyFromKeychain() ?? ""
    }
    
    private func saveAPIKey() {
        KeychainService.shared.saveAPIKey(apiKey)
        savedAPIKey = apiKey
        apiKey = ""
    }
    
    private func deleteAPIKey() {
        KeychainService.shared.deleteAPIKey()
        savedAPIKey = ""
    }
}

/// 声質タイプ
enum VoiceType: String, CaseIterable, Identifiable, RawRepresentable {
    case alloy
    case ash
    case ballad
    case coral
    case echo
    case sage
    case shimmer
    case verse
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alloy: return "Alloy（中性的）"
        case .ash: return "Ash（落ち着いた）"
        case .ballad: return "Ballad（穏やか）"
        case .coral: return "Coral（明るい）"
        case .echo: return "Echo（柔らかい）"
        case .sage: return "Sage（知的）"
        case .shimmer: return "Shimmer（輝く）"
        case .verse: return "Verse（詩的）"
        }
    }
}

#Preview {
    SettingsView()
}
