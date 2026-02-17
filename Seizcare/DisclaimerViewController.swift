//
//  DisclaimerViewController.swift
//  Seizcare
//
//  Created by Student on 25/11/25.
//

import UIKit

class DisclaimerViewController: UIViewController {

    // MARK: - Properties
    var receivedEmail: String?
    var receivedPassword: String?
    var currentUser: User?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Email received: \(receivedEmail ?? "")")
        print("Password received: \(receivedPassword ?? "")")
        
        // Remove back button
        navigationItem.hidesBackButton = true
        
        // Setup UI (called once)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Disable interactive pop gesture
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .systemBackground
        
        // Main scroll view
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Content container view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Main vertical stack view (single source of truth for layout)
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.distribution = .fill
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 44),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        // 1. Warning icon
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        iconImageView.tintColor = .systemRed
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        mainStack.addArrangedSubview(iconImageView)
        mainStack.setCustomSpacing(16, after: iconImageView)
        
        // 2. Title label
        let titleLabel = UILabel()
        titleLabel.text = "Important Medical Notice"
        titleLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(titleLabel)
        titleLabel.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        mainStack.setCustomSpacing(24, after: titleLabel)
        
        // 3. Disclaimer card
        let disclaimerCard = createDisclaimerCard()
        mainStack.addArrangedSubview(disclaimerCard)
        disclaimerCard.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        mainStack.setCustomSpacing(32, after: disclaimerCard)
        
        // 4. "How We Help" title
        let howWeHelpTitle = UILabel()
        howWeHelpTitle.text = "How We Help:"
        howWeHelpTitle.font = .systemFont(ofSize: 18, weight: .semibold)
        howWeHelpTitle.textColor = .label
        howWeHelpTitle.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(howWeHelpTitle)
        howWeHelpTitle.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        howWeHelpTitle.textAlignment = .left
        mainStack.setCustomSpacing(8, after: howWeHelpTitle)
        
        // 5. "How We Help" description
        let howWeHelpBody = UILabel()
        howWeHelpBody.text = "We log detailed seizure data (duration, time, vitals) to provide comprehensive reports for your doctor, improving communication and care."
        howWeHelpBody.font = .systemFont(ofSize: 15, weight: .regular)
        howWeHelpBody.textColor = .secondaryLabel
        howWeHelpBody.numberOfLines = 0
        howWeHelpBody.lineBreakMode = .byWordWrapping
        howWeHelpBody.translatesAutoresizingMaskIntoConstraints = false
        mainStack.addArrangedSubview(howWeHelpBody)
        howWeHelpBody.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        mainStack.setCustomSpacing(40, after: howWeHelpBody)
        
        // 6. Primary button
        let understandButton = UIButton(type: .system)
        understandButton.setTitle("I Understand", for: .normal)
        understandButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        understandButton.backgroundColor = .systemBlue
        understandButton.setTitleColor(.white, for: .normal)
        understandButton.layer.cornerRadius = 26
        understandButton.layer.masksToBounds = true
        understandButton.translatesAutoresizingMaskIntoConstraints = false
        understandButton.addTarget(self, action: #selector(understandButtonTapped), for: .touchUpInside)
        mainStack.addArrangedSubview(understandButton)
        understandButton.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        understandButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
    
    // MARK: - UI Component Factory
    
    private func createDisclaimerCard() -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.93, alpha: 1.0)
        cardView.layer.cornerRadius = 18
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        let textLabel = UILabel()
        textLabel.text = "This application is designed to monitor data and alert contacts based on physiological changes. It is not a medical device and is not intended to diagnose, treat, cure, or prevent any medical condition."
        textLabel.font = .systemFont(ofSize: 15, weight: .regular)
        textLabel.textColor = UIColor(red: 0.7, green: 0.1, blue: 0.0, alpha: 1.0)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        cardView.addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            textLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            textLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            textLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18)
        ])
        
        cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        
        return cardView
    }
    
    // MARK: - Actions
    
    @objc private func understandButtonTapped() {
        // Navigate to Dashboard storyboard
        let dashboardStoryboard = UIStoryboard(name: "Dashboard", bundle: nil)
        if let dashboardVC = dashboardStoryboard.instantiateInitialViewController() {
            navigationController?.pushViewController(dashboardVC, animated: true)
        }
    }
}
