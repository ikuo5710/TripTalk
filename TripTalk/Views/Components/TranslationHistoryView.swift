//
//  TranslationHistoryView.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import SwiftUI

/// 翻訳履歴表示ビュー
struct TranslationHistoryView: View {
    let entries: [TranslationEntry]
    let isTranslating: Bool
    
    init(entries: [TranslationEntry], isTranslating: Bool = false) {
        self.entries = entries
        self.isTranslating = isTranslating
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if entries.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(entries) { entry in
                            TranslationEntryRow(entry: entry)
                                .id(entry.id)
                        }
                        
                        // 最後の要素にスクロールするためのアンカー
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
            }
            .onChange(of: entries) { _, newEntries in
                // エントリ更新時に自動スクロール
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if !entries.isEmpty {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            if isTranslating {
                // 翻訳中の待機状態
                ProgressView()
                    .scaleEffect(1.2)
                Text("音声を聞いています...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "text.bubble")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                Text("翻訳テキストがここに表示されます")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 翻訳エントリ行
struct TranslationEntryRow: View {
    let entry: TranslationEntry
    
    var body: some View {
        if entry.isSeparator {
            separatorView
        } else {
            translationView
        }
    }
    
    private var separatorView: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            
            Text(entry.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
        .padding(.vertical, 12)
    }
    
    private var translationView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // 中間結果の場合は点滅インジケーターを表示
                if entry.isIntermediate {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .opacity(0.7)
                }
                
                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(entry.isIntermediate ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    entry.isIntermediate ? Color.blue.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview("With entries") {
    TranslationHistoryView(
        entries: [
            TranslationEntry(text: "Hello, how are you?", isIntermediate: false),
            TranslationEntry(text: "I'm fine, thank you. How about you? This is a longer text to see how it wraps.", isIntermediate: false),
            TranslationEntry.separator(
                from: .japanese,
                to: .english,
                newFrom: .english,
                newTo: .japanese
            ),
            TranslationEntry(text: "Nice to meet you.", isIntermediate: false),
            TranslationEntry(text: "What's your name...", isIntermediate: true),
        ],
        isTranslating: true
    )
}

#Preview("Empty - Idle") {
    TranslationHistoryView(entries: [], isTranslating: false)
}

#Preview("Empty - Translating") {
    TranslationHistoryView(entries: [], isTranslating: true)
}
