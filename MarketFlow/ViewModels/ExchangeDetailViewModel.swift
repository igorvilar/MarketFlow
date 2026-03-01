//
//  ExchangeDetailViewModel.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation
import Combine

class ExchangeDetailViewModel {
    
    enum State {
        case loading
        case loaded(detail: ExchangeDetail, assets: [Asset])
        case errorMessage(String)
    }
    
    @Published private(set) var state: State = .loading
    
    let exchangeId: Int
    let exchangeName: String
    
    @Inject private var repository: ExchangeRepositoryProtocol
    
    init(exchangeId: Int, exchangeName: String) {
        self.exchangeId = exchangeId
        self.exchangeName = exchangeName
    }
    
    func fetchDetailsAndAssets() {
        self.state = .loading
        
        Task {
            do {
                async let detailTask = repository.fetchExchangeDetails(id: exchangeId)
                async let assetsTask = repository.fetchExchangeAssets(id: exchangeId)
                
                let (detail, assets) = try await (detailTask, assetsTask)
                
                await MainActor.run {
                    self.state = .loaded(detail: detail, assets: assets)
                }
            } catch {
                await MainActor.run {
                    self.state = .errorMessage(error.localizedDescription)
                }
            }
        }
    }
    
    func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "N/A" }
        return value.formatted(.currency(code: "USD"))
    }
    
    func formatPercentage(_ value: Double?) -> String {
        guard let value = value else { return "0%" }
        return value.formatted(.percent.precision(.fractionLength(2)))
    }
    
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString, let date = dateString.parseISODate() else { return "Unknown Launch Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}
