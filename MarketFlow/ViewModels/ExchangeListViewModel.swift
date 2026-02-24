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
    
    // MARK: - Formatters
    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // API Format
        return formatter
    }()
    
    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Helpers
    func formatVolume(_ volume: Double?) -> String {
        guard let volume = volume else { return "Vol: N/A" }
        return currencyFormatter.string(from: NSNumber(value: volume)) ?? "Vol: $" + String(format: "%.0f", volume)
    }
    
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString,
              let date = dateFormatter.date(from: dateString) else {
            return "Launched: Unknown"
        }
        return "Launched: " + displayDateFormatter.string(from: date)
    }
}
