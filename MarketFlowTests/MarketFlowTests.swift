//
//  MarketFlowTests.swift
//  MarketFlowTests
//
//  Created by Igor Vilar on 22/02/26.
//

import Testing
import Foundation
@testable import MarketFlow

// MARK: - Mock Service

class MockMarketDataService: MarketDataServiceProtocol {
    var mockExchanges: [Exchange] = []
    var mockCoins: [Coin] = []
    var mockDetail: ExchangeDetail?
    var mockAssets: [Asset] = []
    var mockError: Error?

    func fetchExchanges(limit: Int) async throws -> [Exchange] {
        if let error = mockError { throw error }
        return mockExchanges
    }

    func fetchCoins(limit: Int) async throws -> [Coin] {
        if let error = mockError { throw error }
        return mockCoins
    }

    func fetchExchangeDetails(id: Int) async throws -> ExchangeDetail {
        if let error = mockError { throw error }
        if let detail = mockDetail { return detail }
        throw NetworkError.notFound
    }

    func fetchExchangeAssets(id: Int) async throws -> [Asset] {
        if let error = mockError { throw error }
        return mockAssets
    }
}

// MARK: - Mock Delegates

@MainActor
class MockListDelegate: ExchangeListViewModelDelegate {
    var states: [NetworkState] = []
    var selectedExchanges: [Exchange] = []
    
    func didUpdateState(_ state: NetworkState) {
        states.append(state)
    }
    
    func didSelectExchange(_ exchange: Exchange) {
        selectedExchanges.append(exchange)
    }
}

@MainActor
class MockDetailDelegate: ExchangeDetailViewModelDelegate {
    var states: [ExchangeDetailViewModel.State] = []
    
    func didUpdateState(_ state: ExchangeDetailViewModel.State) {
        states.append(state)
    }
}


// MARK: - Exchange List Tests

@Suite("Exchange List View Model Tests")
struct ExchangeListViewModelTests {
    
    @Test("Successful fetch states")
    func testFetchExchangesSuccess() async throws {
        let mockService = MockMarketDataService()
        mockService.mockExchanges = [
            Exchange(id: 1, name: "Binance", slug: "binance", firstHistoricalData: "2017-07-14T00:00:00.000Z"),
            Exchange(id: 2, name: "Coinbase", slug: "coinbase", firstHistoricalData: nil)
        ]
        
        let viewModel = ExchangeListViewModel(service: mockService)
        
        // Isolate delegate interactions on MainActor
        let delegate = await MockListDelegate()
        await MainActor.run { viewModel.delegate = delegate }
        
        await MainActor.run { viewModel.fetchExchanges() }
        
        // Wait for unstructured task to complete
        try await Task.sleep(nanoseconds: 50_000_000) 
        
        await MainActor.run {
            #expect(delegate.states.count == 2)
            if case .loading = delegate.states.first {
                #expect(true)
            } else {
                Issue.record("First state should be .loading")
            }
            if case .loaded = delegate.states.last {
                #expect(true)
            } else {
                Issue.record("Last state should be .loaded")
            }
            #expect(viewModel.exchanges.count == 2)
            #expect(viewModel.exchanges[0].name == "Binance")
        }
    }
    
    @Test("Failed fetch error state")
    func testFetchExchangesFailure() async throws {
        let mockService = MockMarketDataService()
        mockService.mockError = NetworkError.forbidden
        
        let viewModel = ExchangeListViewModel(service: mockService)
        let delegate = await MockListDelegate()
        await MainActor.run { viewModel.delegate = delegate }
        
        await MainActor.run { viewModel.fetchExchanges() }
        try await Task.sleep(nanoseconds: 50_000_000)
        
        await MainActor.run {
            #expect(delegate.states.count == 2)
            if case .error(let msg) = delegate.states.last {
                #expect(msg == NetworkError.forbidden.localizedDescription)
            } else {
                Issue.record("Expected .error state")
            }
            #expect(viewModel.exchanges.isEmpty)
        }
    }
    
    @Test("Formatting Volume and Dates")
    func testFormattingHelpersList() async throws {
        let viewModel = ExchangeListViewModel(service: MockMarketDataService())
        
        // Volume
        let formattedVol = viewModel.formatVolume(1234567.89)
        #expect(formattedVol.contains("1,234,568") || formattedVol.contains("1.234.568")) // Varies by locale, but digits math
        
        let nilVol = viewModel.formatVolume(nil)
        #expect(nilVol == "Vol: N/A")
        
        // Dates
        let validDate = viewModel.formatDate("2017-07-14T00:00:00.000Z")
        #expect(validDate.contains("Launched:"))
        #expect(validDate.contains("2017") || validDate.contains("14")) // Varies by locale
        
        let nilDate = viewModel.formatDate(nil)
        #expect(nilDate == "Launched: Unknown")
    }
}

// MARK: - Exchange Detail Tests

@Suite("Exchange Detail View Model Tests")
struct ExchangeDetailViewModelTests {
    
    @Test("Successful concurrent fetch")
    func testFetchDetailsAndAssetsSuccess() async throws {
        let mockService = MockMarketDataService()
        let detail = ExchangeDetail(id: 1, name: "Binance", logo: nil, description: "Desc", makerFee: 0.001, takerFee: 0.002, dateLaunched: "2017-07-14T00:00:00.000Z", urls: nil)
        let assets = [
            Asset(currency: AssetCurrency(name: "Bitcoin", symbol: "BTC", priceUsd: 50000.0)),
            Asset(currency: AssetCurrency(name: "Ethereum", symbol: "ETH", priceUsd: 3000.0))
        ]
        
        mockService.mockDetail = detail
        mockService.mockAssets = assets
        
        let viewModel = ExchangeDetailViewModel(exchangeId: 1, exchangeName: "Binance", marketDataService: mockService)
        let delegate = await MockDetailDelegate()
        await MainActor.run { viewModel.delegate = delegate }
        
        await MainActor.run { viewModel.fetchDetailsAndAssets() }
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            #expect(delegate.states.count == 2)
            if case .loading = delegate.states.first {
                #expect(true)
            } else {
                Issue.record("First state should be loading")
            }
            
            if case .loaded(let fetchedDetail, let fetchedAssets) = delegate.states.last {
                #expect(fetchedDetail.name == "Binance")
                #expect(fetchedDetail.makerFee == 0.001)
                #expect(fetchedAssets.count == 2)
                #expect(fetchedAssets[0].currency.symbol == "BTC")
            } else {
                Issue.record("Expected loaded state with details and assets")
            }
        }
    }
    
    @Test("Failed concurrent fetch due to single endpoint failure")
    func testFetchDetailsAndAssetsFailure() async throws {
        let mockService = MockMarketDataService()
        mockService.mockError = NetworkError.serverError // Simulate 500 error on fetching
        
        let viewModel = ExchangeDetailViewModel(exchangeId: 1, exchangeName: "Binance", marketDataService: mockService)
        let delegate = await MockDetailDelegate()
        await MainActor.run { viewModel.delegate = delegate }
        
        await MainActor.run { viewModel.fetchDetailsAndAssets() }
        try await Task.sleep(nanoseconds: 50_000_000)
        
        await MainActor.run {
            #expect(delegate.states.count == 2)
            if case .errorMessage(let msg) = delegate.states.last {
                #expect(msg == NetworkError.serverError.localizedDescription)
            } else {
                Issue.record("Expected error state")
            }
        }
    }
    
    @Test("Formatting Currencies and Percentages")
    func testFormattingHelpersDetail() async throws {
        let viewModel = ExchangeDetailViewModel(exchangeId: 1, exchangeName: "Binance", marketDataService: MockMarketDataService())
        
        let formattedCurrency = viewModel.formatCurrency(1234.56)
        #expect(formattedCurrency.contains("1,234.56") || formattedCurrency.contains("1.234,56") || formattedCurrency.contains("$"))
        
        let nilCurrency = viewModel.formatCurrency(nil)
        #expect(nilCurrency == "N/A")
        
        let formattedPercentage = viewModel.formatPercentage(0.001)
        #expect(formattedPercentage == "0.10%")
        
        let nilPercentage = viewModel.formatPercentage(nil)
        #expect(nilPercentage == "0%")
    }
}
