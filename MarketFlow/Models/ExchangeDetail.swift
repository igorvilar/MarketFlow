//
//  ExchangeDetail.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

struct ExchangeInfoResponse: Decodable {
    let data: [String: ExchangeDetail]
    let status: APIStatus
}

struct ExchangeDetail: Decodable {
    let id: Int
    let name: String
    let logo: String?
    let description: String?
    let makerFee: Double?
    let takerFee: Double?
    let dateLaunched: String?
    let urls: ExchangeURLs?
    
    enum CodingKeys: String, CodingKey {
        case id, name, logo, description, urls
        case makerFee = "maker_fee"
        case takerFee = "taker_fee"
        case dateLaunched = "date_launched"
    }
}

struct ExchangeURLs: Decodable {
    let website: [String]?
    // Optionally: fee, twitter, etc.
}
