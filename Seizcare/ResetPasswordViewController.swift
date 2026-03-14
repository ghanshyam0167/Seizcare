//
//  ResetPasswordViewController.swift
//  Seizcare
//
//  Created on 12/03/26.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {

    // MARK: - Programmatic Views
    private let inputsContainer = UIView()
    private let passwordField = UITextField()
    private let passwordUnderline = UIView()
    private let passwordIcon = UIImageView()
    private let confirmField = UITextField()
    private let confirmUnderline = UIView()
    private let confirmIcon = UIImageView()
    private let updateButton = UIButton(type: .system)
    private let successView = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.applyWhiteNavBar()
        navigationItem.title = "Set New Password"
        // Prevent going back to OTP directly after this point as the session is logically advanced
        navigationItem.hidesBackButton = true
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
        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = .systemBlue
        lockIcon.contentMode = .scaleAspectFit
        lockCircle.addSubview(lockIcon)

        // ── Title & Subtitle ─────────────────────────────────────
        let titleLabel = UILabel()
        titleLabel.text = "Create New Password"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your new password must be at least\n6 characters long."
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

        let passwordStack = createInputStack(
            label: "New Password",
            field: passwordField,
            placeholder: "Minimum 6 characters",
            underline: passwordUnderline,
            iconView: passwordIcon,
            iconName: "lock",
            isSecure: true
        )
        passwordStack.translatesAutoresizingMaskIntoConstraints = false
        inputsContainer.addSubview(passwordStack)

        let confirmStack = createInputStack(
            label: "Confirm Password",
            field: confirmField,
            placeholder: "Minimum 6 characters",
            underline: confirmUnderline,
            iconView: confirmIcon,
            iconName: "lock.fill",
            isSecure: true
        )
        confirmStack.translatesAutoresizingMaskIntoConstraints = false
        inputsContainer.addSubview(confirmStack)

        // ── Update Button ─────────────────────────────────────────
        updateButton.setTitle("Update Password", for: .normal)
        updateButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        updateButton.setTitleColor(.white, for: .normal)
        updateButton.backgroundColor = .systemBlue
        updateButton.layer.cornerRadius = 27
        updateButton.layer.shadowColor = UIColor.black.cgColor
        updateButton.layer.shadowOpacity = 0.12
        updateButton.layer.shadowRadius = 10
        updateButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        updateButton.layer.masksToBounds = false
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        updateButton.addTarget(self, action: #selector(animateButtonPress(_:)), for: .touchDown)
        updateButton.addTarget(self, action: #selector(animateButtonRelease(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(updateButton)

        // ── Success View (hidden initially) ──────────────────────
        buildSuccessView()

        // ── Constraints ──────────────────────────────────────────
        NSLayoutConstraint.activate([
            lockCircle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            lockCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockCircle.widthAnchor.constraint(equalToConstant: 96),
            lockCircle.heightAnchor.constraint(equalToConstant: 96),

            lockIcon.centerXAnchor.constraint(equalTo: lockCircle.centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: lockCircle.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 40),
            lockIcon.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: lockCircle.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            inputsContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            inputsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            inputsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            passwordStack.topAnchor.constraint(equalTo: inputsContainer.topAnchor, constant: 20),
            passwordStack.leadingAnchor.constraint(equalTo: inputsContainer.leadingAnchor, constant: 20),
            passwordStack.trailingAnchor.constraint(equalTo: inputsContainer.trailingAnchor, constant: -20),

            confirmStack.topAnchor.constraint(equalTo: passwordStack.bottomAnchor, constant: 20),
            confirmStack.leadingAnchor.constraint(equalTo: inputsContainer.leadingAnchor, constant: 20),
            confirmStack.trailingAnchor.constraint(equalTo: inputsContainer.trailingAnchor, constant: -20),
            confirmStack.bottomAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: -20),

            updateButton.topAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: 28),
            updateButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            updateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            updateButton.heightAnchor.constraint(equalToConstant: 54),

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
        successTitle.text = "Password Reset!"
        successTitle.font = .systemFont(ofSize: 24, weight: .bold)
        successTitle.textColor = .label
        successTitle.textAlignment = .center
        successTitle.translatesAutoresizingMaskIntoConstraints = false
        successView.addSubview(successTitle)

        let successSubtitle = UILabel()
        successSubtitle.text = "Your password has been successfully updated.\nYou can now sign in with your new credentials."
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

    // MARK: - Input Stack Helper

    private func createInputStack(label: String, field: UITextField, placeholder: String, underline: UIView, iconView: UIImageView, iconName: String, isSecure: Bool) -> UIStackView {

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
        field.isSecureTextEntry = isSecure
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

    @objc private func updateButtonTapped() {
        let password = passwordField.text ?? ""
        let confirm = confirmField.text ?? ""

        if password.isEmpty || confirm.isEmpty {
            showAlert(title: "Error", message: "Please fill in all fields.")
            return
        }

        if password.count < 6 {
            showAlert(title: "Error", message: "Password must be at least 6 characters.")
            return
        }

        if password != confirm {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }

        // Show loading state
        updateButton.isEnabled = false
        updateButton.setTitle("Updating...", for: .normal)
        updateButton.alpha = 0.7

        Task {
            do {
                try await UserDataModel.shared.updateUserPasswordAsync(newPassword: password)
                
                await MainActor.run {
                    self.updateButton.isEnabled = true
                    self.updateButton.setTitle("Update Password", for: .normal)
                    self.updateButton.alpha = 1.0
                    self.showSuccessState()
                }
            } catch {
                await MainActor.run {
                    self.updateButton.isEnabled = true
                    self.updateButton.setTitle("Update Password", for: .normal)
                    self.updateButton.alpha = 1.0
                    self.showAlert(title: "Update Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func showSuccessState() {
        successView.isHidden = false
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
            self.successView.alpha = 1
        }
    }

    @objc private func backToSignIn() {
        // Find SignInViewController in the stack to pop to
        if let viewControllers = navigationController?.viewControllers {
            for vc in viewControllers {
                if String(describing: type(of: vc)) == "SignInViewController" {
                    // Sign out quietly so user has to log in with new credentials.
                    // This is safe because verifyOTP starts an active Auth session behind the scenes, so
                    // logging out ensures the normal Login flow is utilized.
                    Task {
                        try? await SupabaseService.shared.signOut()
                    }
                    navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Animations

    @objc private func animateButtonPress(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func animateButtonRelease(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            if textField == self.passwordField {
                self.passwordUnderline.backgroundColor = .systemBlue
                self.passwordUnderline.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
                self.passwordIcon.tintColor = .systemBlue
            } else if textField == self.confirmField {
                self.confirmUnderline.backgroundColor = .systemBlue
                self.confirmUnderline.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
                self.confirmIcon.tintColor = .systemBlue
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.25) {
            if textField == self.passwordField {
                self.passwordUnderline.backgroundColor = .systemGray5
                self.passwordUnderline.transform = .identity
                self.passwordIcon.tintColor = .systemGray3
            } else if textField == self.confirmField {
                self.confirmUnderline.backgroundColor = .systemGray5
                self.confirmUnderline.transform = .identity
                self.confirmIcon.tintColor = .systemGray3
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordField {
            confirmField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            updateButtonTapped()
        }
        return true
    }

    // MARK: - Utility

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
