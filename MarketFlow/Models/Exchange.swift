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

struct Exchange: Decodable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let firstHistoricalData: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, slug
        case firstHistoricalData = "first_historical_data"
    }
}
