//
//  MainView.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

/// メイン翻訳画面
struct MainView: View {
    @State private var viewModel = TranslationViewModel()
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 言語選択エリア
                languageSelector
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                Divider()
                
                // 状態表示
                StatusIndicator(state: viewModel.connectionState)
                    .padding(.vertical, 8)
                
                Divider()
                
                // 翻訳履歴
                TranslationHistoryView(entries: viewModel.translationEntries)
                
                Divider()
                
                // コントロールボタン
                ControlButtons(
                    connectionState: viewModel.connectionState,
                    onStart: viewModel.startTranslation,
                    onPause: viewModel.pauseTranslation,
                    onResume: viewModel.resumeTranslation,
                    onStop: viewModel.stopTranslation
                )
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .navigationTitle("TripTalk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    toolbarLeadingItems
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                viewModel.checkAPIKeyAndShowSettingsIfNeeded(showSettings: $showSettings)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var languageSelector: some View {
        HStack(spacing: 8) {
            LanguagePicker(
                title: "入力",
                selection: $viewModel.inputLanguage,
                excludedLanguage: viewModel.outputLanguage,
                isEnabled: !viewModel.connectionState.isSessionActive
            )
            
            Button {
                viewModel.swapLanguages()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(viewModel.connectionState.isSessionActive ? .secondary : .primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .disabled(viewModel.connectionState.isSessionActive)
            
            LanguagePicker(
                title: "出力",
                selection: $viewModel.outputLanguage,
                excludedLanguage: viewModel.inputLanguage,
                isEnabled: !viewModel.connectionState.isSessionActive
            )
        }
    }
    
    private var toolbarLeadingItems: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.copyAllText()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(viewModel.translationEntries.isEmpty)
            
            ShareLink(item: viewModel.allTranslationText) {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(viewModel.translationEntries.isEmpty)
        }
    }
}

#Preview {
    MainView()
}
