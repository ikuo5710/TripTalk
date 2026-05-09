//
//  TripTalkTests.swift
//  TripTalkTests
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Testing
@testable import TripTalk

struct TripTalkTests {

    // MARK: - Language Tests
    
    @Test func languageHas13Cases() {
        #expect(Language.allCases.count == 13)
    }
    
    @Test func languageDisplayNames() {
        #expect(Language.japanese.displayName == "日本語")
        #expect(Language.english.displayName == "英語")
        #expect(Language.spanish.displayName == "スペイン語")
    }
    
    @Test func languageAPINnames() {
        #expect(Language.japanese.apiName == "Japanese")
        #expect(Language.english.apiName == "English")
        #expect(Language.chinese.apiName == "Chinese")
    }
    
    // MARK: - ConnectionState Tests
    
    @Test func connectionStateDisplayText() {
        #expect(ConnectionState.idle.displayText == "未開始")
        #expect(ConnectionState.connecting.displayText == "接続中...")
        #expect(ConnectionState.translating.displayText == "翻訳中")
        #expect(ConnectionState.paused.displayText == "一時停止中")
        #expect(ConnectionState.reconnecting.displayText == "再接続中...")
        #expect(ConnectionState.error("テストエラー").displayText == "テストエラー")
    }
    
    @Test func connectionStateIsSessionActive() {
        #expect(ConnectionState.idle.isSessionActive == false)
        #expect(ConnectionState.connecting.isSessionActive == false)
        #expect(ConnectionState.translating.isSessionActive == true)
        #expect(ConnectionState.paused.isSessionActive == true)
        #expect(ConnectionState.reconnecting.isSessionActive == false)
        #expect(ConnectionState.error("error").isSessionActive == false)
    }
    
    @Test func connectionStateIsTranslating() {
        #expect(ConnectionState.translating.isTranslating == true)
        #expect(ConnectionState.paused.isTranslating == false)
        #expect(ConnectionState.idle.isTranslating == false)
    }
    
    // MARK: - TranslationEntry Tests
    
    @Test func translationEntryCreation() {
        let entry = TranslationEntry(text: "Hello", isIntermediate: false)
        #expect(entry.text == "Hello")
        #expect(entry.isIntermediate == false)
        #expect(entry.isSeparator == false)
    }
    
    @Test func translationEntrySeparator() {
        let separator = TranslationEntry.separator(
            from: .japanese,
            to: .english,
            newFrom: .english,
            newTo: .japanese
        )
        #expect(separator.isSeparator == true)
        #expect(separator.text.contains("日本語"))
        #expect(separator.text.contains("英語"))
    }
    
    // MARK: - KeychainService Tests
    
    @Test func keychainServiceSaveAndGet() {
        let testKey = "test-api-key-\(UUID().uuidString)"
        
        // Save
        KeychainService.shared.saveAPIKey(testKey)
        
        // Get
        let retrievedKey = KeychainService.shared.getAPIKey()
        #expect(retrievedKey == testKey)
        
        // Cleanup
        KeychainService.shared.deleteAPIKey()
    }
    
    @Test func keychainServiceDelete() {
        let testKey = "test-api-key-delete"
        
        // Save
        KeychainService.shared.saveAPIKey(testKey)
        #expect(KeychainService.shared.hasAPIKey() == true)
        
        // Delete
        KeychainService.shared.deleteAPIKey()
        #expect(KeychainService.shared.hasAPIKey() == false)
    }
    
    @Test func keychainServiceHasAPIKey() {
        // Ensure clean state
        KeychainService.shared.deleteAPIKey()
        #expect(KeychainService.shared.hasAPIKey() == false)
        
        // Save key
        KeychainService.shared.saveAPIKey("test-key")
        #expect(KeychainService.shared.hasAPIKey() == true)
        
        // Cleanup
        KeychainService.shared.deleteAPIKey()
    }
    
    @Test func keychainServiceOverwrite() {
        // Save first key
        KeychainService.shared.saveAPIKey("first-key")
        #expect(KeychainService.shared.getAPIKey() == "first-key")
        
        // Overwrite with second key
        KeychainService.shared.saveAPIKey("second-key")
        #expect(KeychainService.shared.getAPIKey() == "second-key")
        
        // Cleanup
        KeychainService.shared.deleteAPIKey()
    }
}
