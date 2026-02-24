//
//  MarketFlowTests.swift
//  MarketFlowTests
//
//  Created by Igor Vilar on 22/02/26.
//

import Testing
import Foundation
import Combine
@testable import MarketFlow

// MARK: - Mock Service

class MockMarketDataService: MarketDataServiceProtocol {
    var mockExchanges: [Exchange] = []
    var mockCoins: [Coin] = []
    var mockDetail: ExchangeDetail?
    var mockAssets: [Asset] = []
    var mockError: Error?

    func fetchExchanges(start: Int, limit: Int) async throws -> [Exchange] {
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

// MARK: - Exchange List Tests

@Suite("All Mock Application Tests", .serialized)
struct MarketFlowAllTests {

    struct ExchangeListViewModelTests {
    
    @Test("Successful fetch states")
    func testFetchExchangesSuccess() async throws {
        // Clear local cache to simulate a fresh install and guarantee .loading -> .loaded state flow
        LocalCacheService.shared.clearCache()
        
        let mockService = MockMarketDataService()
        mockService.mockExchanges = [
            Exchange(id: 1, name: "Binance", slug: "binance", firstHistoricalData: "2017-07-14T00:00:00.000Z"),
            Exchange(id: 2, name: "Coinbase", slug: "coinbase", firstHistoricalData: nil)
        ]
        DIContainer.shared.register(type: MarketDataServiceProtocol.self, component: mockService)
        
        let viewModel = ExchangeListViewModel()
        var states: [NetworkState] = []
        var cancellables = Set<AnyCancellable>()
        
        // Isolate interaction on MainActor
        await MainActor.run {
            viewModel.$state
                .dropFirst() // Ignore the initial default .loading value assigned during init
                .sink { state in
                    states.append(state)
                }
                .store(in: &cancellables)
            
            viewModel.fetchExchanges()
        }
        
        // Wait for unstructured task to complete
        try await Task.sleep(nanoseconds: 50_000_000) 
        
        await MainActor.run {
            #expect(states.count == 2)
            if states.count >= 2 {
                if case .loading = states[0] { #expect(true) } else { Issue.record("First state should be .loading") }
                if case .loaded = states[1] { #expect(true) } else { Issue.record("Last state should be .loaded") }
            }
            #expect(viewModel.exchanges.count == 2)
            #expect(viewModel.exchanges[0].name == "Binance")
        }
    }
    
    @Test("Failed fetch error state")
    func testFetchExchangesFailure() async throws {
        LocalCacheService.shared.clearCache() // Emulate first usage to guarantee Error propagates visually
        let mockService = MockMarketDataService()
        mockService.mockError = NetworkError.forbidden
        DIContainer.shared.register(type: MarketDataServiceProtocol.self, component: mockService)
        
        let viewModel = ExchangeListViewModel()
        var states: [NetworkState] = []
        var cancellables = Set<AnyCancellable>()
        
        await MainActor.run {
            viewModel.$state
                .dropFirst()
                .sink { state in states.append(state) }
                .store(in: &cancellables)
            
            viewModel.fetchExchanges()
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        
        await MainActor.run {
            #expect(states.count == 2)
            if states.count >= 2 {
                if case .loading = states[0] { #expect(true) } else { Issue.record("First state should be .loading") }
                if case .error(let msg) = states[1] {
                    #expect(msg == NetworkError.forbidden.localizedDescription)
                } else {
                    Issue.record("Expected .error state")
                }
            }
            #expect(viewModel.exchanges.isEmpty)
        }
    }
    
    @Test("Formatting Volume and Dates")
    func testFormattingHelpersList() async throws {
        let mockService = MockMarketDataService()
        DIContainer.shared.register(type: MarketDataServiceProtocol.self, component: mockService)
        let viewModel = ExchangeListViewModel()
        
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
        DIContainer.shared.register(type: MarketDataServiceProtocol.self, component: mockService)
        
        let viewModel = ExchangeDetailViewModel(exchangeId: 1, exchangeName: "Binance")
        var states: [ExchangeDetailViewModel.State] = []
        var cancellables = Set<AnyCancellable>()
        
        await MainActor.run {
            viewModel.$state
                .dropFirst()
                .sink { state in states.append(state) }
                .store(in: &cancellables)
            
            viewModel.fetchDetailsAndAssets()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await MainActor.run {
            #expect(states.count == 2)
            if states.count >= 2 {
                if case .loading = states[0] { #expect(true) } else { Issue.record("First state should be loading") }
                
                if case .loaded(let fetchedDetail, let fetchedAssets) = states[1] {
                    #expect(fetchedDetail.name == "Binance")
                    #expect(fetchedDetail.makerFee == 0.001)
                    #expect(fetchedAssets.count == 2)
                    #expect(fetchedAssets[0].currency.symbol == "BTC")
                } else {
                    Issue.record("Expected loaded state with details and assets")
                }
            }
        }
    }
    
    @Test("Failed concurrent fetch due to single endpoint failure")
    func testFetchDetailsAndAssetsFailure() async throws {
        let mockService = MockMarketDataService()
        mockService.mockError = NetworkError.serverError // Simulate 500 error on fetching
        DIContainer.shared.register(type: MarketDataServiceProtocol.self, component: mockService)
        
        let viewModel = ExchangeDetailViewModel(exchangeId: 1, exchangeName: "Binance")
        var states: [ExchangeDetailViewModel.State] = []
        var cancellables = Set<AnyCancellable>()
        
        await MainActor.run {
            viewModel.$state
                .dropFirst()
                .sink { state in states.append(state) }
                .store(in: &cancellables)
            
            viewModel.fetchDetailsAndAssets()
        }
        try await Task.sleep(nanoseconds: 50_000_000)
        
        await MainActor.run {
            #expect(states.count == 2)
            if states.count >= 2 {
                if case .loading = states[0] { #expect(true) } else { Issue.record("First state should be loading") }
                
                if case .errorMessage(let msg) = states[1] {
                    #expect(msg == NetworkError.serverError.localizedDescription)
                } else {
                    Issue.record("Expected error state")
                }
            }
        }
    }
    
    @Test("Formatting Currencies and Percentages")
    func testFormattingHelpersDetail() async throws {
        DIContainer.shared.register(type: MarketDataServiceProtocol.self, component: MockMarketDataService())
        let viewModel = ExchangeDetailViewModel(exchangeId: 1, exchangeName: "Binance")
        
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
}
