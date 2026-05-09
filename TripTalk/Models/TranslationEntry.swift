//
//  TranslationEntry.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// 翻訳エントリ
struct TranslationEntry: Identifiable, Equatable {
    let id: UUID
    var text: String
    var isIntermediate: Bool
    let timestamp: Date
    
    /// 区切り行かどうか
    var isSeparator: Bool
    
    init(
        id: UUID = UUID(),
        text: String,
        isIntermediate: Bool = false,
        timestamp: Date = Date(),
        isSeparator: Bool = false
    ) {
        self.id = id
        self.text = text
        self.isIntermediate = isIntermediate
        self.timestamp = timestamp
        self.isSeparator = isSeparator
    }
    
    /// 言語入れ替え時の区切り行を作成
    static func separator(from: Language, to: Language, newFrom: Language, newTo: Language) -> TranslationEntry {
        TranslationEntry(
            text: "言語を入れ替えました：\(from.displayName) → \(to.displayName) から \(newFrom.displayName) → \(newTo.displayName)",
            isSeparator: true
        )
    }
}
