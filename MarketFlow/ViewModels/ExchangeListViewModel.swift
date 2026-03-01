//
//  ExchangeListViewModel.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation
import Combine

enum NetworkState {
    case loading
    case loaded
    case error(String)
}

class ExchangeListViewModel {
    
    // MARK: - Properties
    @Published private(set) var state: NetworkState = .loading
    weak var coordinator: AppCoordinator?
    
    @Inject private var repository: ExchangeRepositoryProtocol
    
    private(set) var exchanges: [Exchange] = []
    private var isFetchingMore = false
    private var hasMoreData = true
    
    // Pagination Controls
    private var currentStart = 1
    private let limitPerPage = 50
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Fetching Data
    
    func fetchExchanges() {
        if let cachedExchanges = repository.loadCachedExchanges(), !cachedExchanges.isEmpty {
            self.exchanges = cachedExchanges
            self.state = .loaded
        } else {
            self.state = .loading
        }
        
        currentStart = 1
        hasMoreData = true
        
        Task {
            do {
                let freshExchanges = try await repository.fetchExchanges(start: currentStart, limit: limitPerPage)
                self.hasMoreData = freshExchanges.count == limitPerPage
                
                await MainActor.run {
                    self.exchanges = freshExchanges
                    self.repository.saveExchangesToCache(freshExchanges)
                    self.state = .loaded
                }
            } catch {
                await MainActor.run {
                    if self.exchanges.isEmpty {
                        self.state = .error(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func fetchMoreExchanges() {
        guard !isFetchingMore, hasMoreData else { return }
        
        isFetchingMore = true
        currentStart += limitPerPage
        
        Task {
            do {
                let newBatch = try await repository.fetchExchanges(start: currentStart, limit: limitPerPage)
                
                if newBatch.isEmpty {
                    self.hasMoreData = false
                } else {
                    await MainActor.run {
                        self.exchanges.append(contentsOf: newBatch)
                        self.repository.saveExchangesToCache(self.exchanges)
                    }
                }
                
                await MainActor.run {
                    self.isFetchingMore = false
                    self.state = .loaded
                }
            } catch {
                await MainActor.run {
                    self.isFetchingMore = false
                    self.state = .loaded
                }
            }
        }
    }
    
    // MARK: - Helpers
    func formatVolume(_ volume: Double?) -> String {
        guard let volume = volume else { return "Vol: N/A" }
        return "Vol: \(volume.formatted(.currency(code: "USD").precision(.fractionLength(0))))"
    }

    func formatDate(_ dateString: String?) -> String {
        guard let date = dateString?.parseISODate() else { return "Launched: Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US")
        return "Launched: \(formatter.string(from: date))"
    }
}
