//
//  ExchangeListViewModel.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

enum NetworkState {
    case loading
    case loaded
    case error(String)
}

protocol ExchangeListViewModelDelegate: AnyObject {
    func didUpdateState(_ state: NetworkState)
}

class ExchangeListViewModel {
    
    // MARK: - Properties
    weak var delegate: ExchangeListViewModelDelegate?
    private let service: MarketDataServiceProtocol
    private(set) var exchanges: [Exchange] = []
    
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
    
    // MARK: - Init
    init(service: MarketDataServiceProtocol = MarketDataService.shared) {
        self.service = service
    }
    
    // MARK: - Actions
    func fetchExchanges() {
        delegate?.didUpdateState(.loading)
        
        Task {
            do {
                let fetchedExchanges = try await service.fetchExchanges(limit: 50)
                await MainActor.run {
                    self.exchanges = fetchedExchanges
                    self.delegate?.didUpdateState(.loaded)
                }
            } catch {
                await MainActor.run {
                    self.delegate?.didUpdateState(.error(error.localizedDescription))
                }
            }
        }
    }
    
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
