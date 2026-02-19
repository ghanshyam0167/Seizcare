//
//  NUSleepHoursViewController.swift
//  Seizcare
//
//  Created by Jasmeen Grewal on 19/02/26.
//

import UIKit

class NUSleepHoursViewController: UIViewController {

    // MARK: - Data
    private let options = [
        "Less than 5 hours",
        "5–6 hours",
        "6–8 hours",
        "More than 8 hours"
    ]

    private var selectedIndex: Int? = nil

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

    private var rowControls: [NUSleepRowView] = []
    private var continueButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Sleep Duration"
        view.backgroundColor = .systemGroupedBackground

        setupViews()
        setupContinueButton()
        updateContinueButtonState()
    }

    // MARK: - Setup

    private func setupViews() {
        let headerLabel = UILabel()
        headerLabel.text = "How many hours of sleep do you typically get?"
        headerLabel.font = .systemFont(ofSize: 20, weight: .bold)
        headerLabel.textColor = .label
        headerLabel.numberOfLines = 0
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)

        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            headerLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

            cardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20)
        ])

        cardView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])

        for i in 0..<options.count {
            let row = NUSleepRowView(title: options[i])
            row.tag = i
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
            row.addTarget(self, action: #selector(rowTapped(_:)), for: .touchUpInside)
            rowControls.append(row)

            stackView.addArrangedSubview(row)

            if i < options.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }
    }

    private func setupContinueButton() {
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(.lightText, for: .disabled)
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

    @objc private func rowTapped(_ sender: NUSleepRowView) {
        let index = sender.tag

        if let prev = selectedIndex {
            rowControls[prev].setChecked(false, animated: true)
        }

        selectedIndex = index
        rowControls[index].setChecked(true, animated: true)
        updateContinueButtonState()
    }

    @objc private func continueButtonTapped() {
        guard let index = selectedIndex else { return }

        // Save selection
        UserDefaults.standard.set(options[index], forKey: "typicalSleepHours")

        // Navigate to Seizure Time screen
        let timeVC = storyboard?.instantiateViewController(withIdentifier: "NUSeizureTimeVC") as! NUSeizureTimeViewController
        navigationController?.pushViewController(timeVC, animated: true)
    }

    // MARK: - Helpers

    private func updateContinueButtonState() {
        let isEnabled = selectedIndex != nil
        continueButton?.isEnabled = isEnabled
        continueButton?.alpha = isEnabled ? 1.0 : 0.5
    }
}

// MARK: - NUSleepRowView

private class NUSleepRowView: UIControl {
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
        isUserInteractionEnabled = true
        isExclusiveTouch = true
        backgroundColor = .clear

        isAccessibilityElement = true
        accessibilityTraits = .button

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label

        checkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkImageView.tintColor = .systemBlue
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.alpha = 0

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
            hStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),

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
