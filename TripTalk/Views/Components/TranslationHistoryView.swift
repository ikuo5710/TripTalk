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
                    }
                    .padding()
                }
            }
            .onChange(of: entries.count) { _, _ in
                if let lastEntry = entries.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("翻訳テキストがここに表示されます")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
        HStack {
            VStack { Divider() }
            Text(entry.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            VStack { Divider() }
        }
        .padding(.vertical, 8)
    }
    
    private var translationView: some View {
        Text(entry.text)
            .font(.body)
            .foregroundStyle(entry.isIntermediate ? .secondary : .primary)
            .opacity(entry.isIntermediate ? 0.7 : 1.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}

#Preview("With entries") {
    TranslationHistoryView(entries: [
        TranslationEntry(text: "Hello, how are you?", isIntermediate: false),
        TranslationEntry(text: "I'm fine, thank you. How about you?", isIntermediate: false),
        TranslationEntry.separator(
            from: .japanese,
            to: .english,
            newFrom: .english,
            newTo: .japanese
        ),
        TranslationEntry(text: "Nice to meet you.", isIntermediate: false),
        TranslationEntry(text: "What's your name...", isIntermediate: true),
    ])
}

#Preview("Empty") {
    TranslationHistoryView(entries: [])
}
