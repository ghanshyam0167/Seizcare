//
//  LanguageTableViewController.swift
//  Seizcare
//
//  Created by Student on 21/11/25.
//

import UIKit

class LanguageTableViewController: UIViewController {

    // MARK: - Data
    private let languages = ["English", "Hindi", "Marathi", "Bengali", "Tamil"] // align with Language enum
    private var selectedIndex = 2 // Default = English (index 0), but keeping 2 as initial

    // MARK: - Views
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.layer.shadowRadius = 8
        return v
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 0
        return sv
    }()

    private var rowControls: [LanguageRowView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = UILabel()
        titleLabel.text = "Language".localized()
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        navigationItem.titleView = titleLabel

        view.backgroundColor = .systemGroupedBackground

        loadSavedPreference()
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28)
        ])

        cardView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])

        // Create language rows
        for i in 0..<languages.count {
            let row = LanguageRowView(title: languages[i])
            row.tag = i
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            rowControls.append(row)

            stackView.addArrangedSubview(row)

            // Add divider between rows (but not after last row)
            if i < languages.count - 1 {
                let divider = createDivider()
                stackView.addArrangedSubview(divider)
            }
        }

        // Set initial checkmark state
        for (i, r) in rowControls.enumerated() {
            r.setChecked(i == selectedIndex, animated: false)
        }
    }

    // MARK: - Helpers

    private func createDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return divider
    }

    // MARK: - Actions

    @objc private func rowTapped(_ sender: LanguageRowView) {
        let index = sender.tag
        guard index != selectedIndex else { return }

        let previous = selectedIndex
        selectedIndex = index
        
        // Update UI immediately (checkmarks)
        rowControls[previous].setChecked(false, animated: true)
        rowControls[selectedIndex].setChecked(true, animated: true)

        // Set Language via Manager (this triggers root reload)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let selectedLanguage: Language
            switch index {
            case 0: selectedLanguage = .english
            case 1: selectedLanguage = .hindi
            case 2: selectedLanguage = .marathi
            case 3: selectedLanguage = .bengali
            case 4: selectedLanguage = .tamil
            default: selectedLanguage = .english
            }
            LanguageManager.shared.setLanguage(selectedLanguage)
        }
    }

    // MARK: - Persistence

    private func loadSavedPreference() {
        let current = LanguageManager.shared.currentLanguage
        switch current {
        case .english: selectedIndex = 0
        case .hindi: selectedIndex = 1
        case .marathi: selectedIndex = 2
        case .bengali: selectedIndex = 3
        case .tamil: selectedIndex = 4
        }
    }
}

// MARK: - LanguageRowView

private class LanguageRowView: UIControl {
    private let titleLabel = UILabel()
    private let checkImageView = UIImageView()

    init(title: String) {
        super.init(frame: .zero)
        setup(title: title)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "")
    }

    private func setup(title: String) {
        // UIControl configuration
        self.isUserInteractionEnabled = true
        self.isExclusiveTouch = true
        self.backgroundColor = .clear

        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits = .button

        // Title Label
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.isUserInteractionEnabled = false

        // Checkmark ImageView
        checkImageView.image = UIImage(systemName: "checkmark")
        checkImageView.tintColor = .systemBlue
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.alpha = 0
        checkImageView.isUserInteractionEnabled = false

        // Main horizontal stack
        let hStack = UIStackView(arrangedSubviews: [titleLabel, checkImageView])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 12
        hStack.isUserInteractionEnabled = false

        addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            checkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func setChecked(_ checked: Bool, animated: Bool) {
        let animations = {
            self.checkImageView.alpha = checked ? 1.0 : 0.0
        }

        if animated {
            UIView.transition(with: checkImageView, duration: 0.22, options: [.transitionCrossDissolve], animations: animations, completion: nil)
        } else {
            animations()
        }
        accessibilityValue = checked ? "Selected" : "Not selected"
    }
}
