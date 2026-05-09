//
//  Language.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// 対応言語（13言語）
enum Language: String, CaseIterable, Identifiable {
    case spanish = "es"
    case portuguese = "pt"
    case french = "fr"
    case japanese = "ja"
    case russian = "ru"
    case chinese = "zh"
    case german = "de"
    case korean = "ko"
    case hindi = "hi"
    case indonesian = "id"
    case vietnamese = "vi"
    case italian = "it"
    case english = "en"
    
    var id: String { rawValue }
    
    /// 表示名（日本語）
    var displayName: String {
        switch self {
        case .spanish: return "スペイン語"
        case .portuguese: return "ポルトガル語"
        case .french: return "フランス語"
        case .japanese: return "日本語"
        case .russian: return "ロシア語"
        case .chinese: return "中国語"
        case .german: return "ドイツ語"
        case .korean: return "韓国語"
        case .hindi: return "ヒンディー語"
        case .indonesian: return "インドネシア語"
        case .vietnamese: return "ベトナム語"
        case .italian: return "イタリア語"
        case .english: return "英語"
        }
    }
    
    /// OpenAI API用の言語コード（ISO 639-1）
    var apiCode: String {
        rawValue  // es, pt, fr, ja, ru, zh, de, ko, hi, id, vi, it, en
    }
}
