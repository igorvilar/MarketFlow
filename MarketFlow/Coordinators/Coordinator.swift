//
//  Coordinator.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import UIKit

protocol Coordinator {
    var navigationController: UINavigationController { get set }
    func start()
}

//
//  AppCoordinator.swift
//

class AppCoordinator: Coordinator {
    
    var navigationController: UINavigationController
    
    @Inject private var exchangeListViewModel: ExchangeListViewModel
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // Large titles look nice for Market apps
        self.navigationController.navigationBar.prefersLargeTitles = true 
    }
    
    func start() {
        exchangeListViewModel.coordinator = self
        let exchangeVC = ExchangeListViewController(viewModel: exchangeListViewModel)
        navigationController.pushViewController(exchangeVC, animated: false)
    }
    
    func showExchangeDetail(exchange: Exchange) {
        let detailViewModel = ExchangeDetailViewModel(exchangeId: exchange.id, exchangeName: exchange.name)
        let detailVC = ExchangeDetailViewController(viewModel: detailViewModel)
        navigationController.pushViewController(detailVC, animated: true)
    }
}
