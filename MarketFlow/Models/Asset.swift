//
//  Asset.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

struct ExchangeAssetsResponse: Decodable {
    let data: [Asset]
    let status: APIStatus
}

struct Asset: Decodable {
    let currency: AssetCurrency
}

struct AssetCurrency: Decodable {
    let name: String
    let symbol: String
    let priceUsd: Double?
    
    enum CodingKeys: String, CodingKey {
        case name, symbol
        case priceUsd = "price_usd"
    }
}
