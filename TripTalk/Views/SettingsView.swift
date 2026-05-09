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
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
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

#Preview {
    SettingsView()
}
