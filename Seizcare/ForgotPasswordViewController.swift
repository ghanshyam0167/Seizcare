//
//  ForgotPasswordViewController.swift
//  Seizcare
//
//  Created on 12/03/26.
//

import UIKit

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Programmatic Views
    private let inputsContainer = UIView()
    private let emailField = UITextField()
    private let emailUnderline = UIView()
    private let emailIcon = UIImageView()
    private let resetButton = UIButton(type: .system)
    private let successView = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.applyWhiteNavBar()
        navigationItem.title = "Forgot Password"
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemGray6

        // ── Lock Icon ────────────────────────────────────────────
        let lockCircle = UIView()
        lockCircle.translatesAutoresizingMaskIntoConstraints = false
        lockCircle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        lockCircle.layer.cornerRadius = 48
        view.addSubview(lockCircle)

        let lockIcon = UIImageView()
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.image = UIImage(systemName: "lock.rotation")
        lockIcon.tintColor = .systemBlue
        lockIcon.contentMode = .scaleAspectFit
        lockCircle.addSubview(lockIcon)

        // ── Title & Subtitle ─────────────────────────────────────
        let titleLabel = UILabel()
        titleLabel.text = "Reset Your Password"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Enter your email address and we'll send\nyou a link to reset your password."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        // ── Input Container Card ─────────────────────────────────
        inputsContainer.backgroundColor = .white
        inputsContainer.layer.cornerRadius = 22
        inputsContainer.layer.shadowColor = UIColor.black.cgColor
        inputsContainer.layer.shadowOpacity = 0.06
        inputsContainer.layer.shadowRadius = 14
        inputsContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        inputsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputsContainer)

        let emailStack = createInputStack(
            label: "Email Address",
            field: emailField,
            placeholder: "Enter your registered email",
            underline: emailUnderline,
            iconView: emailIcon,
            iconName: "envelope"
        )
        emailStack.translatesAutoresizingMaskIntoConstraints = false
        inputsContainer.addSubview(emailStack)

        // ── Reset Button ─────────────────────────────────────────
        resetButton.setTitle("Send Reset Link", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = .systemBlue
        resetButton.layer.cornerRadius = 27
        resetButton.layer.shadowColor = UIColor.black.cgColor
        resetButton.layer.shadowOpacity = 0.12
        resetButton.layer.shadowRadius = 10
        resetButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        resetButton.layer.masksToBounds = false
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(animateButtonPress), for: .touchDown)
        resetButton.addTarget(self, action: #selector(animateButtonRelease), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)

        // ── Success View (hidden initially) ──────────────────────
        buildSuccessView()

        // ── Constraints ──────────────────────────────────────────
        NSLayoutConstraint.activate([
            // Lock circle
            lockCircle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            lockCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockCircle.widthAnchor.constraint(equalToConstant: 96),
            lockCircle.heightAnchor.constraint(equalToConstant: 96),

            lockIcon.centerXAnchor.constraint(equalTo: lockCircle.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockCircle.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 40),
            lockIcon.heightAnchor.constraint(equalToConstant: 40),

            // Title
            titleLabel.topAnchor.constraint(equalTo: lockCircle.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            // Input container
            inputsContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            inputsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            inputsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            emailStack.topAnchor.constraint(equalTo: inputsContainer.topAnchor, constant: 20),
            emailStack.leadingAnchor.constraint(equalTo: inputsContainer.leadingAnchor, constant: 20),
            emailStack.trailingAnchor.constraint(equalTo: inputsContainer.trailingAnchor, constant: -20),
            emailStack.bottomAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: -20),

            // Reset button
            resetButton.topAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: 28),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            resetButton.heightAnchor.constraint(equalToConstant: 54),

            // Success view
            successView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            successView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            successView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            successView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Success View

    private func buildSuccessView() {
        successView.backgroundColor = .systemGray6
        successView.alpha = 0
        successView.isHidden = true
        successView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(successView)

        // Checkmark circle
        let checkCircle = UIView()
        checkCircle.translatesAutoresizingMaskIntoConstraints = false
        checkCircle.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        checkCircle.layer.cornerRadius = 48
        successView.addSubview(checkCircle)

        let checkIcon = UIImageView()
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkIcon.image = UIImage(systemName: "checkmark.circle.fill")
        checkIcon.tintColor = .systemGreen
        checkIcon.contentMode = .scaleAspectFit
        checkCircle.addSubview(checkIcon)

        let successTitle = UILabel()
        successTitle.text = "Email Sent!"
        successTitle.font = .systemFont(ofSize: 24, weight: .bold)
        successTitle.textColor = .label
        successTitle.textAlignment = .center
        successTitle.translatesAutoresizingMaskIntoConstraints = false
        successView.addSubview(successTitle)

        let successSubtitle = UILabel()
        successSubtitle.text = "We've sent a password reset link to\nyour email address. Please check your\ninbox and follow the instructions."
        successSubtitle.font = .systemFont(ofSize: 15, weight: .regular)
        successSubtitle.textColor = .secondaryLabel
        successSubtitle.textAlignment = .center
        successSubtitle.numberOfLines = 0
        successSubtitle.translatesAutoresizingMaskIntoConstraints = false
        successView.addSubview(successSubtitle)

        let backToLoginBtn = UIButton(type: .system)
        backToLoginBtn.setTitle("Back to Sign In", for: .normal)
        backToLoginBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        backToLoginBtn.setTitleColor(.white, for: .normal)
        backToLoginBtn.backgroundColor = .systemBlue
        backToLoginBtn.layer.cornerRadius = 27
        backToLoginBtn.layer.shadowColor = UIColor.black.cgColor
        backToLoginBtn.layer.shadowOpacity = 0.12
        backToLoginBtn.layer.shadowRadius = 10
        backToLoginBtn.layer.shadowOffset = CGSize(width: 0, height: 4)
        backToLoginBtn.addTarget(self, action: #selector(backToSignIn), for: .touchUpInside)
        backToLoginBtn.translatesAutoresizingMaskIntoConstraints = false
        successView.addSubview(backToLoginBtn)

        NSLayoutConstraint.activate([
            checkCircle.centerXAnchor.constraint(equalTo: successView.centerXAnchor),
            checkCircle.topAnchor.constraint(equalTo: successView.topAnchor, constant: 120),
            checkCircle.widthAnchor.constraint(equalToConstant: 96),
            checkCircle.heightAnchor.constraint(equalToConstant: 96),

            checkIcon.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            checkIcon.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 48),
            checkIcon.heightAnchor.constraint(equalToConstant: 48),

            successTitle.topAnchor.constraint(equalTo: checkCircle.bottomAnchor, constant: 24),
            successTitle.centerXAnchor.constraint(equalTo: successView.centerXAnchor),

            successSubtitle.topAnchor.constraint(equalTo: successTitle.bottomAnchor, constant: 12),
            successSubtitle.leadingAnchor.constraint(equalTo: successView.leadingAnchor, constant: 40),
            successSubtitle.trailingAnchor.constraint(equalTo: successView.trailingAnchor, constant: -40),

            backToLoginBtn.topAnchor.constraint(equalTo: successSubtitle.bottomAnchor, constant: 36),
            backToLoginBtn.leadingAnchor.constraint(equalTo: successView.leadingAnchor, constant: 24),
            backToLoginBtn.trailingAnchor.constraint(equalTo: successView.trailingAnchor, constant: -24),
            backToLoginBtn.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    // MARK: - Input Stack Helper (matches SignInViewController style)

    private func createInputStack(label: String, field: UITextField, placeholder: String, underline: UIView, iconView: UIImageView, iconName: String) -> UIStackView {

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 16, weight: .semibold)
        labelView.textColor = .label

        let config = UIImage.SymbolConfiguration(weight: .regular)
        iconView.image = UIImage(systemName: iconName, withConfiguration: config)
        iconView.tintColor = .systemGray3
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true

        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.textColor = .label
        field.borderStyle = .none
        field.autocapitalizationType = .none
        field.keyboardType = .emailAddress
        field.returnKeyType = .done
        field.delegate = self

        if let ph = field.placeholder {
            field.attributedPlaceholder = NSAttributedString(
                string: ph,
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            )
        }

        let fieldStack = UIStackView(arrangedSubviews: [iconView, field])
        fieldStack.axis = .horizontal
        fieldStack.spacing = 12
        fieldStack.alignment = .center

        underline.backgroundColor = .separator.withAlphaComponent(0.4)
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        let mainStack = UIStackView(arrangedSubviews: [labelView, fieldStack, underline])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.setCustomSpacing(8, after: labelView)
        mainStack.setCustomSpacing(10, after: fieldStack)

        return mainStack
    }

    // MARK: - Actions

    @objc private func resetButtonTapped() {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if email.isEmpty {
            showAlert(title: "Error", message: "Please enter your email address.")
            return
        }

        if !email.contains("@") || !email.contains(".") {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }

        // Show success state with animation
        showSuccessState()
    }

    private func showSuccessState() {
        successView.isHidden = false
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
            self.successView.alpha = 1
        }
    }

    @objc private func backToSignIn() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Animations

    @objc private func animateButtonPress() {
        UIView.animate(withDuration: 0.1) {
            self.resetButton.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func animateButtonRelease() {
        UIView.animate(withDuration: 0.1) {
            self.resetButton.transform = .identity
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnim.fromValue = 0.04
        shadowAnim.toValue = 0.08
        shadowAnim.duration = 0.2
        inputsContainer.layer.add(shadowAnim, forKey: "shadowOpacity")
        inputsContainer.layer.shadowOpacity = 0.08

        UIView.animate(withDuration: 0.25) {
            self.emailUnderline.backgroundColor = .systemBlue
            self.emailUnderline.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
            self.emailIcon.tintColor = .systemBlue
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnim.fromValue = 0.08
        shadowAnim.toValue = 0.04
        shadowAnim.duration = 0.2
        inputsContainer.layer.add(shadowAnim, forKey: "shadowOpacity")
        inputsContainer.layer.shadowOpacity = 0.04

        UIView.animate(withDuration: 0.25) {
            self.emailUnderline.backgroundColor = .systemGray5
            self.emailUnderline.transform = .identity
            self.emailIcon.tintColor = .systemGray3
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        resetButtonTapped()
        return true
    }

    // MARK: - Utility

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
