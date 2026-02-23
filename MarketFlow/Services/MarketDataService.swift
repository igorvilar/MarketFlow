//
//  MarketDataService.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

protocol MarketDataServiceProtocol {
    func fetchExchanges(start: Int, limit: Int) async throws -> [Exchange]
    func fetchCoins(limit: Int) async throws -> [Coin]
    func fetchExchangeDetails(id: Int) async throws -> ExchangeDetail
    func fetchExchangeAssets(id: Int) async throws -> [Asset]
}

class MarketDataService: MarketDataServiceProtocol {
    
    static let shared = MarketDataService()
    
    private let baseURL = Constants.API.baseURL
    private let apiKey = Constants.API.apiKey
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchExchanges(start: Int = 1, limit: Int = 20) async throws -> [Exchange] {
        guard var components = URLComponents(string: "\(baseURL)/v1/exchange/map") else {
            throw NetworkError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "start", value: "\(start)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        let data = try await performRequest(url: url)
        
        do {
            let response = try JSONDecoder().decode(ExchangeResponse.self, from: data)
            return response.data
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func fetchCoins(limit: Int = 20) async throws -> [Coin] {
        // We are using /v1/cryptocurrency/map as requested to fetch coins
        guard var components = URLComponents(string: "\(baseURL)/v1/cryptocurrency/map") else {
            throw NetworkError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        let data = try await performRequest(url: url)
        
        do {
            let response = try JSONDecoder().decode(CoinResponse.self, from: data)
            return response.data
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func fetchExchangeDetails(id: Int) async throws -> ExchangeDetail {
        guard var components = URLComponents(string: "\(baseURL)/v1/exchange/info") else {
            throw NetworkError.invalidURL
        }
        
        components.queryItems = [URLQueryItem(name: "id", value: "\(id)")]
        guard let url = components.url else { throw NetworkError.invalidURL }
        
        let data = try await performRequest(url: url)
        
        do {
            let response = try JSONDecoder().decode(ExchangeInfoResponse.self, from: data)
            guard let detail = response.data["\(id)"] else {
                throw NetworkError.custom(message: "Exchange details not found in payload.")
            }
            return detail
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func fetchExchangeAssets(id: Int) async throws -> [Asset] {
        guard var components = URLComponents(string: "\(baseURL)/v1/exchange/assets") else {
            throw NetworkError.invalidURL
        }
        
        components.queryItems = [URLQueryItem(name: "id", value: "\(id)")]
        guard let url = components.url else { throw NetworkError.invalidURL }
        
        let data = try await performRequest(url: url)
        
        do {
            let response = try JSONDecoder().decode(ExchangeAssetsResponse.self, from: data)
            return response.data
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    private func performRequest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Check for API level error even if HTTP was 200 OK, CMCP API does this sometimes
            if let root = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let status = root["status"] as? [String: Any],
               let errorCode = status["error_code"] as? Int, errorCode != 0 {
                let errorMessage = status["error_message"] as? String
                throw NetworkError.apiError(code: errorCode, message: errorMessage)
            }
            return data
        case 400: throw NetworkError.badRequest
        case 401: throw NetworkError.unauthorized
        case 403: throw NetworkError.forbidden
        case 404: throw NetworkError.notFound
        case 500...599: throw NetworkError.serverError
        default:
            throw NetworkError.custom(message: "Unexpected statusCode: \(httpResponse.statusCode)")
        }
    }
}
