//
//  NetworkError.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

enum NetworkError: Error {
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
}
