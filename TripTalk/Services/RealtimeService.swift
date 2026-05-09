//
//  RealtimeService.swift
//  TripTalk
//
//  Created by 鈴木生雄 on 2026/05/09.
//

import Foundation

/// OpenAI Realtime API接続サービス
final class RealtimeService {
    static let shared = RealtimeService()
    
    private init() {}
    
    // MARK: - Types
    
    /// クライアントシークレットレスポンス
    struct ClientSecretResponse: Codable {
        let clientSecret: ClientSecret
        
        enum CodingKeys: String, CodingKey {
            case clientSecret = "client_secret"
        }
        
        struct ClientSecret: Codable {
            let value: String
            let expiresAt: Int
            
            enum CodingKeys: String, CodingKey {
                case value
                case expiresAt = "expires_at"
            }
        }
    }
    
    /// セッション設定
    struct SessionConfig: Codable {
        let model: String
        let audio: AudioConfig
        
        struct AudioConfig: Codable {
            let input: InputConfig?
            let output: OutputConfig
            
            struct InputConfig: Codable {
                let transcription: TranscriptionConfig?
                let noiseReduction: NoiseReductionConfig?
                
                enum CodingKeys: String, CodingKey {
                    case transcription
                    case noiseReduction = "noise_reduction"
                }
                
                struct TranscriptionConfig: Codable {
                    let model: String
                }
                
                struct NoiseReductionConfig: Codable {
                    let type: String
                }
            }
            
            struct OutputConfig: Codable {
                let language: String
            }
        }
    }
    
    /// APIエラー
    enum RealtimeError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case httpError(Int, String?)
        case networkError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return Constants.ErrorMessage.invalidAPIKey
            case .invalidResponse:
                return "無効なレスポンスです"
            case .httpError(let code, let message):
                if code == 401 {
                    return Constants.ErrorMessage.invalidAPIKey
                } else if code == 429 {
                    return Constants.ErrorMessage.rateLimitExceeded
                }
                return message ?? "HTTPエラー: \(code)"
            case .networkError:
                return Constants.ErrorMessage.connectionFailed
            }
        }
    }
    
    // MARK: - Properties
    
    private let translationsBaseURL = "https://api.openai.com/v1/realtime/translations"
    private let model = "gpt-realtime-translate"
    
    // MARK: - Public Methods
    
    /// クライアントシークレットを取得（翻訳セッション用）
    /// - Parameter outputLanguage: 出力言語コード（例: "ja", "en"）
    /// - Returns: クライアントシークレット
    func getClientSecret(outputLanguage: String) async throws -> String {
        guard let apiKey = KeychainService.shared.getAPIKey() else {
            throw RealtimeError.noAPIKey
        }
        
        let url = URL(string: "\(translationsBaseURL)/client_secrets")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // セッション設定
        let sessionConfig = SessionConfig(
            model: model,
            audio: SessionConfig.AudioConfig(
                input: SessionConfig.AudioConfig.InputConfig(
                    transcription: SessionConfig.AudioConfig.InputConfig.TranscriptionConfig(
                        model: "gpt-realtime-whisper"
                    ),
                    noiseReduction: SessionConfig.AudioConfig.InputConfig.NoiseReductionConfig(
                        type: "near_field"
                    )
                ),
                output: SessionConfig.AudioConfig.OutputConfig(
                    language: outputLanguage  // Already lowercase ISO 639-1 code
                )
            )
        )
        
        let requestBody = ["session": sessionConfig]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RealtimeError.invalidResponse
            }
            
            // デバッグ: レスポンスを出力
            if let responseString = String(data: data, encoding: .utf8) {
                print("[RealtimeService] Response (\(httpResponse.statusCode)): \(responseString)")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8)
                throw RealtimeError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            let decoded = try JSONDecoder().decode(ClientSecretResponse.self, from: data)
            return decoded.clientSecret.value
            
        } catch let error as RealtimeError {
            throw error
        } catch {
            print("[RealtimeService] Decode error: \(error)")
            throw RealtimeError.networkError(error)
        }
    }
    
    /// SDPオファーを送信してアンサーを取得
    /// - Parameters:
    ///   - sdpOffer: SDPオファー文字列
    ///   - clientSecret: クライアントシークレット
    /// - Returns: SDPアンサー文字列
    func sendSDPOffer(sdpOffer: String, clientSecret: String) async throws -> String {
        let url = URL(string: translationsBaseURL)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = sdpOffer.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RealtimeError.invalidResponse
            }
            
            if httpResponse.statusCode != 201 && httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8)
                throw RealtimeError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            guard let sdpAnswer = String(data: data, encoding: .utf8) else {
                throw RealtimeError.invalidResponse
            }
            
            return sdpAnswer
            
        } catch let error as RealtimeError {
            throw error
        } catch {
            throw RealtimeError.networkError(error)
        }
    }
}
