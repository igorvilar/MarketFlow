//
//  Coin.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

struct CoinResponse: Decodable {
    let data: [Coin]
    let status: APIStatus
}

struct Coin: Decodable, Identifiable {
    let id: Int
    let name: String
    let symbol: String
    let slug: String
    let isActive: Int
    let rank: Int?
    let firstHistoricalData: String?
    let lastHistoricalData: String?
    let platform: Platform?
    
    enum CodingKeys: String, CodingKey {
        case id, name, symbol, slug, platform
        case isActive = "is_active"
        case rank
        case firstHistoricalData = "first_historical_data"
        case lastHistoricalData = "last_historical_data"
    }
}

struct Platform: Decodable {
    let id: Int
    let name: String
    let symbol: String
    let slug: String
    let tokenAddress: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, symbol, slug
        case tokenAddress = "token_address"
    }
}
