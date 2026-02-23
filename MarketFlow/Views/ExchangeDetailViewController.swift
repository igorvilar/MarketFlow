//
//  ExchangeDetailViewController.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import UIKit

class ExchangeDetailViewController: UIViewController {

    let viewModel: ExchangeDetailViewModel
    private var assets: [Asset] = []
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.accessibilityIdentifier = "ExchangeDetailScrollView"
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Header Components
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 32
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let logoInitialLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let metricsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let makerFeeLabel = UILabel()
    private let takerFeeLabel = UILabel()
    private let launchDateLabel = UILabel()
    private let websiteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Visit Website", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Bottom Components (Coins Table)
    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Available Assets"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(CoinTableViewCell.self, forCellReuseIdentifier: "CoinCell")
        tv.accessibilityIdentifier = "ExchangeDetailAssetsTable"
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isScrollEnabled = false // Scroll is handled by the outer scrollView
        return tv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = "DetailLoadingIndicator"
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var tableViewHeightConstraint: NSLayoutConstraint!
    var websiteURL: URL?

    // MARK: - Init
    
    init(viewModel: ExchangeDetailViewModel) {
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
        title = viewModel.exchangeName
        
        viewModel.delegate = self
        viewModel.fetchDetailsAndAssets()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(activityIndicator)
        
        [logoImageView, nameLabel, metricsStack, websiteButton, descriptionLabel, sectionTitleLabel, tableView].forEach {
            contentView.addSubview($0)
        }
        logoImageView.addSubview(logoInitialLabel)
        
        // Configuration for metrics labels
        [makerFeeLabel, takerFeeLabel, launchDateLabel].forEach {
            $0.font = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = .systemGray
            $0.numberOfLines = 2
            $0.textAlignment = .center
            metricsStack.addArrangedSubview($0)
        }
        
        websiteButton.addTarget(self, action: #selector(openWebsite), for: .touchUpInside)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0) // Will update dynamically
        
        NSLayoutConstraint.activate([
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // ScrollView & ContentView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 64),
            logoImageView.heightAnchor.constraint(equalToConstant: 64),
            
            logoInitialLabel.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor),
            logoInitialLabel.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Metrics Stack
            metricsStack.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            metricsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            metricsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Website Button
            websiteButton.topAnchor.constraint(equalTo: metricsStack.bottomAnchor, constant: 16),
            websiteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Section Title
            sectionTitleLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 32),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tableViewHeightConstraint
        ])
    }
    
    // MARK: - Actions
    
    @objc private func openWebsite() {
        guard let url = websiteURL else { return }
        UIApplication.shared.open(url)
    }
    
    private func updateUI(with detail: ExchangeDetail) {
        nameLabel.text = detail.name
        descriptionLabel.text = detail.description ?? "No description available."
        
        makerFeeLabel.text = "Maker Fee\n\(viewModel.formatPercentage(detail.makerFee))"
        takerFeeLabel.text = "Taker Fee\n\(viewModel.formatPercentage(detail.takerFee))"
        launchDateLabel.text = "Launched\n\(viewModel.formatDate(detail.dateLaunched))"
        
        if let websiteStr = detail.urls?.website?.first, let url = URL(string: websiteStr) {
            websiteURL = url
            websiteButton.isHidden = false
        } else {
            websiteButton.isHidden = true
        }
        
        // Logo Loading Cache Fetch
        if let logoStr = detail.logo, let url = URL(string: logoStr) {
            Task {
                if let image = try? await ImageCache.shared.loadImage(from: url) {
                    await MainActor.run { self.logoImageView.image = image }
                }
            }
        } else {
            logoInitialLabel.isHidden = false
            logoInitialLabel.text = String(detail.name.first ?? "?").uppercased()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update TableView height to fit content within the ScrollView without its own scrolling.
        let tvHeight = tableView.contentSize.height
        if tvHeight > 0 && tvHeight != tableViewHeightConstraint.constant {
            tableViewHeightConstraint.constant = tvHeight
            view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource, Delegate

extension ExchangeDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CoinCell", for: indexPath) as? CoinTableViewCell else {
            return UITableViewCell()
        }
        let asset = assets[indexPath.row]
        let priceStr = viewModel.formatCurrency(asset.currency.priceUsd)
        cell.configure(with: asset, formattedPrice: priceStr)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - ExchangeDetailViewModelDelegate

extension ExchangeDetailViewController: ExchangeDetailViewModelDelegate {
    func didUpdateState(_ state: ExchangeDetailViewModel.State) {
        switch state {
        case .loading:
            activityIndicator.startAnimating()
            scrollView.isHidden = true
        case .loaded(let detail, let fetchedAssets):
            activityIndicator.stopAnimating()
            scrollView.isHidden = false
            self.assets = fetchedAssets
            updateUI(with: detail)
            tableView.reloadData()
            view.setNeedsLayout()
        case .errorMessage(let message):
            activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                self.viewModel.fetchDetailsAndAssets()
            })
            alert.addAction(UIAlertAction(title: "Back", style: .cancel) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
}
