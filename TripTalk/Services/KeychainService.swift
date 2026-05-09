//
//  KeychainService.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation
import Security

/// Keychainを使用したAPIキー管理サービス
final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.triptalk.apikey"
    private let accountName = "openai-api-key"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// APIキーを保存
    func saveAPIKey(_ apiKey: String) {
        guard let data = apiKey.data(using: .utf8) else { return }
        
        // 既存のキーを削除
        deleteAPIKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }
    
    /// APIキーを取得
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return apiKey
    }
    
    /// APIキーを削除
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// APIキーが保存されているか確認
    func hasAPIKey() -> Bool {
        getAPIKey() != nil
    }
}
