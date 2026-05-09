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
    @State private var showShareSheet = false
    
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
                TranslationHistoryView(
                    entries: viewModel.translationEntries,
                    isTranslating: viewModel.connectionState.isTranslating
                )
                
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
            .alert("マイクの許可が必要です", isPresented: $viewModel.showMicrophonePermissionAlert) {
                Button("設定を開く") {
                    viewModel.openSettings()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("音声を翻訳するには、マイクへのアクセスを許可してください。設定アプリでマイクをオンにすると、翻訳を開始できます。")
            }
            .onAppear {
                viewModel.checkAPIKeyAndShowSettingsIfNeeded(showSettings: $showSettings)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [viewModel.allTranslationText])
            }
            .overlay(alignment: .top) {
                if viewModel.showCopyConfirmation {
                    CopyConfirmationToast()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.showCopyConfirmation)
                }
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
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            
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
            // ミュートボタン
            Button {
                viewModel.isMuted.toggle()
            } label: {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }
            
            Button {
                viewModel.copyAllText()
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .disabled(viewModel.translationEntries.isEmpty)
            
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(viewModel.translationEntries.isEmpty)
        }
    }
}

// MARK: - CopyConfirmationToast

/// コピー完了通知トースト
struct CopyConfirmationToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("コピーしました")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .padding(.top, 60)
    }
}

// MARK: - ShareSheet

/// UIActivityViewControllerをSwiftUIで使用するためのラッパー
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MainView()
}
