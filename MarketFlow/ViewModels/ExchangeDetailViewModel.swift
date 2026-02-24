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
    
    @Inject private var marketDataService: MarketDataServiceProtocol
    
    init(exchangeId: Int, exchangeName: String) {
        self.exchangeId = exchangeId
        self.exchangeName = exchangeName
    }
    
    func fetchDetailsAndAssets() {
        self.state = .loading
        
        Task {
            do {
                async let detailTask = marketDataService.fetchExchangeDetails(id: exchangeId)
                async let assetsTask = marketDataService.fetchExchangeAssets(id: exchangeId)
                
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "N/A"
    }
    
    func formatPercentage(_ value: Double?) -> String {
        guard let value = value else { return "0%" }
        return String(format: "%.2f%%", value * 100) // Assuming API returns 0.001 for 0.1%
    }
    
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Unknown Launch Date" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else {
            // fallback if it doesn't have fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let fallbackDate = formatter.date(from: dateString) else { return "Unknown Launch Date" }
            return formatDateOnly(fallbackDate)
        }
        return formatDateOnly(date)
    }
    
    private func formatDateOnly(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}
