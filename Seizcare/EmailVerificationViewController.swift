//
//  EmailVerificationViewController.swift
//  Seizcare
//
//  Created on 12/03/26.
//

import UIKit

class EmailVerificationViewController: UIViewController, UITextFieldDelegate {

    private let pendingUser: User
    private let isResend: Bool

    // MARK: - Programmatic Views
    private let inputsContainer = UIView()
    private let otpField = UITextField()
    private let otpUnderline = UIView()
    private let otpIcon = UIImageView()
    private let verifyButton = UIButton(type: .system)

    // MARK: - Initialization

    init(pendingUser: User, isResend: Bool) {
        self.pendingUser = pendingUser
        self.isResend = isResend
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.applyWhiteNavBar()
        navigationItem.title = "Verify Email"
        // Prevent dismissal until verification or manual cancellation button
        navigationItem.hidesBackButton = true
        let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSignup))
        navigationItem.leftBarButtonItem = cancelItem
        
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemGray6

        // ── Mail Icon ────────────────────────────────+++++++++++
        let iconCircle = UIView()
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        iconCircle.layer.cornerRadius = 48
        view.addSubview(iconCircle)

        let mailIcon = UIImageView()
        mailIcon.translatesAutoresizingMaskIntoConstraints = false
        mailIcon.image = UIImage(systemName: "envelope.badge.fill")
        mailIcon.tintColor = .systemBlue
        mailIcon.contentMode = .scaleAspectFit
        iconCircle.addSubview(mailIcon)

        // ── Title & Subtitle ─────────────────────────────────────
        let titleLabel = UILabel()
        titleLabel.text = "Verify Your Email"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        if isResend {
            subtitleLabel.text = "This email is already registered but not verified.\nA new 8-digit confirmation code has been sent to \(pendingUser.email)."
        } else {
            subtitleLabel.text = "Please enter the 8-digit confirmation code\nsent to \(pendingUser.email)."
        }
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

        let otpStack = createInputStack(
            label: "Confirmation Code",
            field: otpField,
            placeholder: "12345678",
            underline: otpUnderline,
            iconView: otpIcon,
            iconName: "number"
        )
        otpStack.translatesAutoresizingMaskIntoConstraints = false
        inputsContainer.addSubview(otpStack)

        // ── Verify Button ─────────────────────────────────────────
        verifyButton.setTitle("Complete Sign Up", for: .normal)
        verifyButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.backgroundColor = .systemBlue
        verifyButton.layer.cornerRadius = 27
        verifyButton.layer.shadowColor = UIColor.black.cgColor
        verifyButton.layer.shadowOpacity = 0.12
        verifyButton.layer.shadowRadius = 10
        verifyButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        verifyButton.layer.masksToBounds = false
        verifyButton.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(animateButtonPress), for: .touchDown)
        verifyButton.addTarget(self, action: #selector(animateButtonRelease), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verifyButton)

        // ── Constraints ──────────────────────────────────────────
        NSLayoutConstraint.activate([
            // icon circle
            iconCircle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            iconCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconCircle.widthAnchor.constraint(equalToConstant: 96),
            iconCircle.heightAnchor.constraint(equalToConstant: 96),

            mailIcon.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            mailIcon.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            mailIcon.widthAnchor.constraint(equalToConstant: 40),
            mailIcon.heightAnchor.constraint(equalToConstant: 40),

            // Title
            titleLabel.topAnchor.constraint(equalTo: iconCircle.bottomAnchor, constant: 24),
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

            otpStack.topAnchor.constraint(equalTo: inputsContainer.topAnchor, constant: 20),
            otpStack.leadingAnchor.constraint(equalTo: inputsContainer.leadingAnchor, constant: 20),
            otpStack.trailingAnchor.constraint(equalTo: inputsContainer.trailingAnchor, constant: -20),
            otpStack.bottomAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: -20),

            // Verify button
            verifyButton.topAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: 28),
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            verifyButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    // MARK: - Input Stack Helper

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
        // Keyboard type numerical for OTPs
        field.keyboardType = .numberPad
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

    @objc private func verifyButtonTapped() {
        let otp = (otpField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if otp.isEmpty {
            showAlert(title: "Error", message: "Please enter the verification code.")
            return
        }

        // Show loading state
        verifyButton.isEnabled = false
        verifyButton.setTitle("Verifying & Finalizing...", for: .normal)
        verifyButton.alpha = 0.7

        Task {
            do {
                try await UserDataModel.shared.finalizeSignUpAsync(user: pendingUser, otp: otp, isResend: isResend)
                
                // Session is ready. Navigate into the dashboard.
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.verifyButton.setTitle("Complete Sign Up", for: .normal)
                    self.verifyButton.alpha = 1.0
                    print("[EmailVerifyVC] finalizeSignUp succeeded. Transitioning to dashboard.")
                    self.transitionToDashboard()
                }
            } catch {
                print("[EmailVerifyVC] finalizeSignUp threw error: \(error)")
                await MainActor.run {
                    self.verifyButton.isEnabled = true
                    self.verifyButton.setTitle("Complete Sign Up", for: .normal)
                    self.verifyButton.alpha = 1.0
                    self.showAlert(title: "Verification Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func transitionToDashboard() {
        print("[EmailVerifyVC] transitionToDashboard called")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainAppVC = storyboard.instantiateViewController(withIdentifier: "MainAppTabBarController") as? UITabBarController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = mainAppVC
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                print("[EmailVerifyVC] Navigation to dashboard complete.")
            } else {
                print("[EmailVerifyVC] ERROR: Could not find window scene.")
            }
        } else {
            print("[EmailVerifyVC] ERROR: Could not instantiate MainAppTabBarController from storyboard.")
        }
    }
    
    @objc private func cancelSignup() {
        // Technically their auth account is established but their profile table record isn't.
        // It's safest to sign out of the unverified auth session locally so they can
        // try again from scratch if they back out.
        Task {
            try? await SupabaseService.shared.signOut()
            await MainActor.run {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - Animations

    @objc private func animateButtonPress() {
        UIView.animate(withDuration: 0.1) {
            self.verifyButton.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func animateButtonRelease() {
        UIView.animate(withDuration: 0.1) {
            self.verifyButton.transform = .identity
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
            self.otpUnderline.backgroundColor = .systemBlue
            self.otpUnderline.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
            self.otpIcon.tintColor = .systemBlue
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
            self.otpUnderline.backgroundColor = .systemGray5
            self.otpUnderline.transform = .identity
            self.otpIcon.tintColor = .systemGray3
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        verifyButtonTapped()
        return true
    }

    // MARK: - Utility

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
