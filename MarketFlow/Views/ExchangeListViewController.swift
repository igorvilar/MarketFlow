//
//  ExchangeListViewController.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import UIKit

class ExchangeListViewController: UIViewController {

    // MARK: - Properties
    
    private let viewModel: ExchangeListViewModel
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none
        table.dataSource = self
        table.delegate = self
        table.register(ExchangeTableViewCell.self, forCellReuseIdentifier: "ExchangeCell")
        table.accessibilityIdentifier = "ExchangeListTable"
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = "ListLoadingIndicator"
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Init
    
    init(viewModel: ExchangeListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        viewModel.delegate = self
        viewModel.fetchExchanges()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        title = "Top Exchanges"
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Error Handling
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.viewModel.fetchExchanges()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension ExchangeListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.exchanges.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ExchangeCell", for: indexPath) as? ExchangeTableViewCell else {
            return UITableViewCell()
        }
        
        let exchange = viewModel.exchanges[indexPath.section]
        let volumeStr = "Vol: N/A (Free API)"
        let dateStr = viewModel.formatDate(exchange.firstHistoricalData)
        
        cell.configure(with: exchange, volumeText: volumeStr, dateText: dateStr)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 4 // Top Spacing between cards
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 4 // Bottom Spacing between cards
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let exchange = viewModel.exchanges[indexPath.section]
        viewModel.delegate?.didSelectExchange(exchange)
    }
    
    // MARK: - Pagination Tracking
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // If user scrolled within 100pt of the bottom edge, trigger pagination
        if offsetY > contentHeight - height - 100 {
            // Attach a small spinner to the bottom purely for visual feedback
            if tableView.tableFooterView == nil && !viewModel.exchanges.isEmpty {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.startAnimating()
                spinner.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
                tableView.tableFooterView = spinner
            }
            
            viewModel.fetchMoreExchanges()
        }
    }
}

// MARK: - ViewModel Delegate

extension ExchangeListViewController: ExchangeListViewModelDelegate {
    
    func didUpdateState(_ state: NetworkState) {
        switch state {
        case .loading:
            loadingIndicator.startAnimating()
            tableView.isHidden = true
        case .loaded:
            loadingIndicator.stopAnimating()
            tableView.tableFooterView = nil // Hide pagination spinner if any
            tableView.isHidden = false
            tableView.reloadData()
        case .error(let message):
            loadingIndicator.stopAnimating()
            showErrorAlert(message: message)
        }
    }
    
    func didSelectExchange(_ exchange: Exchange) {
        viewModel.coordinator?.showExchangeDetail(exchange: exchange)
    }
}
