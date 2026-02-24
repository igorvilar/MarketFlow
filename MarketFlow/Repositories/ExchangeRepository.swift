//
//  ExchangeRepository.swift
//  MarketFlow
//
//  Created by Igor Vilar on 23/02/26.
//

import Foundation

protocol ExchangeRepositoryProtocol {
    func loadCachedExchanges() -> [Exchange]?
    func saveExchangesToCache(_ exchanges: [Exchange])
    func fetchExchanges(start: Int, limit: Int) async throws -> [Exchange]
    func fetchExchangeDetails(id: Int) async throws -> ExchangeDetail
    func fetchExchangeAssets(id: Int) async throws -> [Asset]
}

class ExchangeRepository: ExchangeRepositoryProtocol {
    
    @Inject private var networkService: MarketDataServiceProtocol
    
    init() {}
    
    // MARK: - Local Cache
    
    func loadCachedExchanges() -> [Exchange]? {
        return LocalCacheService.shared.loadExchanges()
    }
    
    func saveExchangesToCache(_ exchanges: [Exchange]) {
        LocalCacheService.shared.saveExchanges(exchanges)
    }
    
    // MARK: - Network Data
    
    func fetchExchanges(start: Int, limit: Int) async throws -> [Exchange] {
        return try await networkService.fetchExchanges(start: start, limit: limit)
    }
    
    func fetchExchangeDetails(id: Int) async throws -> ExchangeDetail {
        return try await networkService.fetchExchangeDetails(id: id)
    }
    
    func fetchExchangeAssets(id: Int) async throws -> [Asset] {
        return try await networkService.fetchExchangeAssets(id: id)
    }
}
