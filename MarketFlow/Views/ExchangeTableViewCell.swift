//
//  ExchangeTableViewCell.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import UIKit

class ExchangeTableViewCell: UITableViewCell {

    // MARK: - UI Components
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let logoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 24 // Half of width/height (48)
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let logoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let volumeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLaunchedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    
    private func setupView() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.addSubview(logoContainerView)
        logoContainerView.addSubview(logoLabel)
        
        cardView.addSubview(stackView)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(volumeLabel)
        
        cardView.addSubview(dateLaunchedLabel)
        
        NSLayoutConstraint.activate([
            // Card View constraints (adding some padding from the cell bounds)
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Logo boundaries
            logoContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            logoContainerView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            logoContainerView.widthAnchor.constraint(equalToConstant: 48),
            logoContainerView.heightAnchor.constraint(equalToConstant: 48),
            logoContainerView.topAnchor.constraint(greaterThanOrEqualTo: cardView.topAnchor, constant: 16),
            logoContainerView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16),
            
            // Logo Label inside Logo Container
            logoLabel.centerXAnchor.constraint(equalTo: logoContainerView.centerXAnchor),
            logoLabel.centerYAnchor.constraint(equalTo: logoContainerView.centerYAnchor),
            
            // StackView for Name and Volume
            stackView.leadingAnchor.constraint(equalTo: logoContainerView.trailingAnchor, constant: 16),
            stackView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: cardView.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16),
            
            // Date Launched (top right)
            dateLaunchedLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            dateLaunchedLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dateLaunchedLabel.leadingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: 8),
            
            // Ensure the card has a minimum height if neither stack nor logo push it enough
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with exchange: Exchange, volumeText: String, dateText: String) {
        nameLabel.text = exchange.name
        volumeLabel.text = volumeText
        dateLaunchedLabel.text = dateText
        
        // Use first letter of exchange name as placeholder logo
        if let firstChar = exchange.name.first {
            logoLabel.text = String(firstChar).uppercased()
        } else {
            logoLabel.text = "?"
        }
    }
}
