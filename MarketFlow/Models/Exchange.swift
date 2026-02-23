//
//  Exchange.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

struct ExchangeResponse: Decodable {
    let data: [Exchange]
    let status: APIStatus
}

struct Exchange: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let firstHistoricalData: String?
    
    var logoURL: URL? {
        return URL(string: "https://s2.coinmarketcap.com/static/img/exchanges/64x64/\(id).png")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug
        case firstHistoricalData = "first_historical_data"
    }
}
