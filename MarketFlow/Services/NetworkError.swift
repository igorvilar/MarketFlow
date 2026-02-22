//
//  NetworkError.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case decodingError(Error)
    case unknown(Error)
    case custom(message: String)
    case apiError(code: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .invalidResponse: return "Invalid response from server."
        case .badRequest: return "Bad request."
        case .unauthorized: return "Unauthorized API Key."
        case .forbidden: return "Forbidden. You may not have access to this endpoint."
        case .notFound: return "Endpoint not found."
        case .serverError: return "Internal server error."
        case .decodingError(let error): return "Failed to decode data: \(error.localizedDescription)"
        case .unknown(let error): return "Unknown error: \(error.localizedDescription)"
        case .custom(let message): return message
        case .apiError(let code, let message): return "API Error \(code): \(message ?? "Unknown reason")"
        }
    }
}
