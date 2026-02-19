//
//  NUAdjustSensitivityViewController.swift
//  Seizcare
//
//  Created by Jasmeen Grewal on 19/02/26.
//

import UIKit

class NUAdjustSensitivityViewController: UIViewController {

    // MARK: - Data
    private let sensitivities = ["Low", "Medium", "High"]

    private let descriptions = [
        "Triggers alerts only for strong seizure patterns",
        "Balanced detection for everyday use",
        "Highly sensitive, detects even mild activity"
    ]

    private var selectedIndex = 1 // Default = Medium

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

    private var rowControls: [NUSensitivityRowView] = []
    private var continueButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Adjust Sensitivity"
        view.backgroundColor = .systemGroupedBackground

        loadSavedPreference()
        setupViews()
        setupContinueButton()
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

        for i in 0..<sensitivities.count {
            let row = NUSensitivityRowView(title: sensitivities[i], subtitle: descriptions[i])
            row.tag = i
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            rowControls.append(row)

            stackView.addArrangedSubview(row)

            if i < sensitivities.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }

        for (i, r) in rowControls.enumerated() {
            r.setChecked(i == selectedIndex, animated: false)
        }
    }

    private func setupContinueButton() {
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 14
        continueButton.layer.masksToBounds = true
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)

        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    @objc private func rowTapped(_ sender: NUSensitivityRowView) {
        let index = sender.tag
        guard index != selectedIndex else { return }

        let previous = selectedIndex
        selectedIndex = index

        // Persist
        UserDefaults.standard.set(sensitivities[selectedIndex], forKey: "sensitivityLevel")

        // Animate change
        rowControls[previous].setChecked(false, animated: true)
        rowControls[selectedIndex].setChecked(true, animated: true)
    }

    @objc private func continueButtonTapped() {
        // Save selection
        UserDefaults.standard.set(sensitivities[selectedIndex], forKey: "sensitivityLevel")

        // Navigate to Seizure Duration screen
        let durationVC = storyboard?.instantiateViewController(withIdentifier: "NUSeizureDurationVC") as! NUSeizureDurationViewController
        navigationController?.pushViewController(durationVC, animated: true)
    }

    // MARK: - Persistence

    private func loadSavedPreference() {
        if let savedLevel = UserDefaults.standard.string(forKey: "sensitivityLevel"),
           let index = sensitivities.firstIndex(of: savedLevel) {
            selectedIndex = index
        }
    }
}

// MARK: - NUSensitivityRowView

private class NUSensitivityRowView: UIControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let checkImageView = UIImageView()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "", subtitle: "")
    }

    private func setup(title: String, subtitle: String) {
        isUserInteractionEnabled = true
        isExclusiveTouch = true
        backgroundColor = .clear

        isAccessibilityElement = true
        accessibilityTraits = .button

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        checkImageView.image = UIImage(systemName: "checkmark")
        checkImageView.tintColor = .systemBlue
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.alpha = 0

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.alignment = .leading
        labelsStack.isUserInteractionEnabled = false

        let hStack = UIStackView(arrangedSubviews: [labelsStack, checkImageView])
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
