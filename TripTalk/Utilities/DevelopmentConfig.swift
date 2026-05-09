//
//  DevelopmentConfig.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// 開発時の設定を管理するクラス
/// リリースビルドでは無効化される
enum DevelopmentConfig {
    
    /// .envファイルからAPIキーを読み込む（開発時のみ）
    /// - Returns: .envファイルに記載されたAPIキー、または nil
    static func loadAPIKeyFromEnv() -> String? {
        #if DEBUG
        // プロジェクトルートの.envファイルを探す
        guard let projectPath = findProjectRoot() else {
            print("[DevelopmentConfig] Project root not found")
            return nil
        }
        
        let envPath = projectPath.appendingPathComponent(".env")
        
        guard FileManager.default.fileExists(atPath: envPath.path) else {
            print("[DevelopmentConfig] .env file not found at \(envPath.path)")
            return nil
        }
        
        do {
            let contents = try String(contentsOf: envPath, encoding: .utf8)
            let apiKey = contents.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // APIキーが空でないか、有効な形式かチェック
            if apiKey.isEmpty {
                print("[DevelopmentConfig] .env file is empty")
                return nil
            }
            
            // OpenAI APIキーの形式チェック（sk-で始まる）
            if apiKey.hasPrefix("sk-") {
                print("[DevelopmentConfig] Loaded API key from .env")
                return apiKey
            }
            
            // KEY=VALUE形式の場合
            if let value = parseEnvFile(contents: contents, key: "OPENAI_API_KEY") {
                print("[DevelopmentConfig] Loaded API key from .env (OPENAI_API_KEY)")
                return value
            }
            
            // 単純にファイル内容をAPIキーとして返す
            print("[DevelopmentConfig] Loaded API key from .env (raw)")
            return apiKey
            
        } catch {
            print("[DevelopmentConfig] Failed to read .env: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// プロジェクトルートを探す
    private static func findProjectRoot() -> URL? {
        #if DEBUG
        // シミュレーターまたは実機での実行時、Bundle.main.bundlePathから辿る
        var url = Bundle.main.bundleURL
        
        // 最大10階層まで遡る
        for _ in 0..<10 {
            let envPath = url.appendingPathComponent(".env")
            if FileManager.default.fileExists(atPath: envPath.path) {
                return url
            }
            
            let parentURL = url.deletingLastPathComponent()
            if parentURL == url {
                break
            }
            url = parentURL
        }
        
        // Xcodeのビルド設定から取得を試みる
        if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
            return URL(fileURLWithPath: srcRoot)
        }
        
        // カレントディレクトリから探す
        let currentPath = FileManager.default.currentDirectoryPath
        var currentURL = URL(fileURLWithPath: currentPath)
        
        for _ in 0..<10 {
            let envPath = currentURL.appendingPathComponent(".env")
            if FileManager.default.fileExists(atPath: envPath.path) {
                return currentURL
            }
            
            let parentURL = currentURL.deletingLastPathComponent()
            if parentURL == currentURL {
                break
            }
            currentURL = parentURL
        }
        
        return nil
        #else
        return nil
        #endif
    }
    
    /// .envファイルをパースしてキーに対応する値を取得
    private static func parseEnvFile(contents: String, key: String) -> String? {
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") { continue } // コメント行をスキップ
            
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 && String(parts[0]).trimmingCharacters(in: .whitespaces) == key {
                return String(parts[1]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}
