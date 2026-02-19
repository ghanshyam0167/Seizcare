//
//  SignInViewController.swift
//  Seizcare
//

import UIKit

class SignInViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var EmailOrPhNo: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!

    // MARK: - Properties for Programmatic UI
    private let inputsContainer = UIView()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let emailUnderline = UIView()
    private let passwordUnderline = UIView()
    private let emailIcon = UIImageView()
    private let passwordIcon = UIImageView()
    private let signInButton = UIButton(type: .system)
    // Removed gradientLayer for simpler look

    // MARK: - Sign In Action
    @IBAction func SignInAction(_ sender: Any) {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let password = passwordField.text ?? ""

        debugLog("User entered → Email: \(email), Password: \(password)")

        if email.isEmpty || password.isEmpty {
            showAlert(message: "Please enter email or phone and password.")
            return
        }

        debugLog("Attempting login with UserDataModel…")
        let loginSuccess = UserDataModel.shared.loginUser(emailOrPhone: email, password: password)

        if loginSuccess {
            debugLog("Login SUCCESS → UserDataModel accepted credentials.")
            performSegue(withIdentifier: "goToNextScreen", sender: self)
        } else {
            debugLog("Login FAILED → No matching user in stored users.")
            showAlert(message: "Invalid email or password.")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Navigation Bar
        navigationController?.applyWhiteNavBar()
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = "Sign In" // You might want to remove this if you want a cleaner look, but keeping per logic
        
        // Build Custom UI
        setupUI()
    }
    
    // Removed viewDidLayoutSubviews as gradient is gone

    // MARK: - Programmatic UI Setup
    private func setupUI() {
        view.subviews.forEach { $0.removeFromSuperview() }
        view.backgroundColor = .systemGray6
        
        // 1. Logo
        let iconView = UIImageView(image: UIImage(named: "Image"))
        iconView.contentMode = .scaleAspectFit
        
        // Logo Constraints (Explicit Size: 240pt)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 240).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        
        // Logo Shadow
        iconView.layer.shadowColor = UIColor.black.cgColor
        iconView.layer.shadowOpacity = 0.08
        iconView.layer.shadowRadius = 12
        iconView.layer.shadowOffset = CGSize(width: 0, height: 6)
        
        // 2. Input Container (Softer White Surface)
        inputsContainer.backgroundColor = .white
        inputsContainer.layer.cornerRadius = 22
        // Subtle Shadow (Opacity 0.06, Radius 14, Offset 0,6)
        inputsContainer.layer.shadowColor = UIColor.black.cgColor
        inputsContainer.layer.shadowOpacity = 0.06
        inputsContainer.layer.shadowRadius = 14
        inputsContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        inputsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. Email Field Row
        let emailStack = createInputStack(
            label: "Email or Phone",
            field: emailField,
            placeholder: "Enter email or phone",
            underline: emailUnderline,
            iconView: emailIcon,
            iconName: "envelope"
        )
        
        // 4. Password Field Row
        let passwordStack = createInputStack(
            label: "Password",
            field: passwordField,
            placeholder: "Enter password",
            underline: passwordUnderline,
            iconView: passwordIcon,
            iconName: "lock",
            isSecure: true
        )
        
        // Combine into main stack inside container
        let inputsStack = UIStackView(arrangedSubviews: [emailStack, passwordStack])
        inputsStack.axis = .vertical
        inputsStack.spacing = 20 // Increased to 20pt
        inputsStack.translatesAutoresizingMaskIntoConstraints = false
        
        inputsContainer.addSubview(inputsStack)
        
        // 5. Sign In Button
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.backgroundColor = .systemBlue
        signInButton.layer.cornerRadius = 27 // Pill style (Height 54 / 2)
        
        // Button Shadow (Opacity 0.12, Radius 10, Offset 0,4)
        signInButton.layer.shadowColor = UIColor.black.cgColor
        signInButton.layer.shadowOpacity = 0.12
        signInButton.layer.shadowRadius = 10
        signInButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        signInButton.layer.masksToBounds = false
        
        signInButton.addTarget(self, action: #selector(SignInAction(_:)), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(animateButtonPress), for: .touchDown)
        signInButton.addTarget(self, action: #selector(animateButtonRelease), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 6. Bottom Links
        let noAccountButton = UIButton(type: .system)
        let signUpAttributed = NSMutableAttributedString(
            string: "Don't have an account? ",
            attributes: [.font: UIFont.systemFont(ofSize: 15), .foregroundColor: UIColor.black]
        )
        signUpAttributed.append(NSAttributedString(
            string: "Sign Up",
            attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .bold), .foregroundColor: UIColor.systemBlue]
        ))
        noAccountButton.setAttributedTitle(signUpAttributed, for: .normal)
        noAccountButton.addTarget(self, action: #selector(goToSignUp), for: .touchUpInside)
        
        let forgotPasswordButton = UIButton(type: .system)
        forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
        forgotPasswordButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium) // Slightly smaller
        forgotPasswordButton.setTitleColor(.systemBlue, for: .normal)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        
        let bottomStack = UIStackView(arrangedSubviews: [noAccountButton, forgotPasswordButton])
        bottomStack.axis = .vertical
        bottomStack.spacing = 14 // Increased to 14pt
        bottomStack.alignment = .center
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to main view
        view.addSubview(iconView)
        view.addSubview(inputsContainer)
        view.addSubview(signInButton)
        view.addSubview(bottomStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Logo: 20pt from top safe area (Title) - Tighter Spacing
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Container: 20pt below Logo - Tighter Spacing
            inputsContainer.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            inputsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24), // Margins 24
            inputsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Inputs Stack: Vertical Padding 20 inside container
            inputsStack.topAnchor.constraint(equalTo: inputsContainer.topAnchor, constant: 20),
            inputsStack.leadingAnchor.constraint(equalTo: inputsContainer.leadingAnchor, constant: 20),
            inputsStack.trailingAnchor.constraint(equalTo: inputsContainer.trailingAnchor, constant: -20),
            inputsStack.bottomAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: -20),
            
            // Button: 30pt below Container - Standard Spacing
            signInButton.topAnchor.constraint(equalTo: inputsContainer.bottomAnchor, constant: 30),
            signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24), // Margins 24
            signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            signInButton.heightAnchor.constraint(equalToConstant: 54),
            
            // Bottom Stack: 20pt below Button
            bottomStack.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),
            bottomStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - Helper: Create Input Stack
    private func createInputStack(label: String, field: UITextField, placeholder: String, underline: UIView, iconView: UIImageView, iconName: String, isSecure: Bool = false) -> UIStackView {
        
        // 1. Label
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 16, weight: .semibold) // Semibold 16
        labelView.textColor = .label // Default label color (black/white)
        
        // 2. Icon Setup
        let config = UIImage.SymbolConfiguration(weight: .regular)
        iconView.image = UIImage(systemName: iconName, withConfiguration: config)
        iconView.tintColor = .systemGray3
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // 3. Field Setup
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.textColor = .label
        field.borderStyle = .none
        field.isSecureTextEntry = isSecure
        
        if label.contains("Email") {
            field.autocapitalizationType = .none
            field.keyboardType = .emailAddress
        }
        field.delegate = self
        
        if let ph = field.placeholder {
            field.attributedPlaceholder = NSAttributedString(string: ph, attributes: [.foregroundColor: UIColor.secondaryLabel]) // Secondary label color
        }
        
        // Stack for Icon + Field
        let fieldStack = UIStackView(arrangedSubviews: [iconView, field])
        fieldStack.axis = .horizontal
        fieldStack.spacing = 12
        fieldStack.alignment = .center
        
        // 4. Underline / Separator
        underline.backgroundColor = .separator.withAlphaComponent(0.4) // Light separator
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        
        // Combine all
        let mainStack = UIStackView(arrangedSubviews: [labelView, fieldStack, underline])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.setCustomSpacing(8, after: labelView)
        mainStack.setCustomSpacing(10, after: fieldStack) // Space between field and underline
        
        return mainStack
    }

    // MARK: - Animations
    @objc private func animateButtonPress() {
        UIView.animate(withDuration: 0.1) {
            self.signInButton.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }
    
    @objc private func animateButtonRelease() {
        UIView.animate(withDuration: 0.1) {
            self.signInButton.transform = .identity
        }
    }

    // MARK: - Actions
    @objc private func goToSignUp() {
        if let signUpVC = storyboard?.instantiateViewController(withIdentifier: "SignUpViewController") {
            navigationController?.pushViewController(signUpVC, animated: true)
        }
    }
    
    @objc private func forgotPasswordTapped() {
        debugLog("Forgot Password Tapped")
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNextScreen" {
            if let nextVC = segue.destination as? DisclaimerViewController {
                nextVC.currentUser = UserDataModel.shared.getCurrentUser()
            }
        }
    }

    // MARK: - Utility
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func debugLog(_ message: String) {
        print("[DEBUG] \(message)")
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let isEmail = (textField == emailField)
        let underline = isEmail ? emailUnderline : passwordUnderline
        let icon = isEmail ? emailIcon : passwordIcon
        
        // Animate Container Shadow Opacity
        let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnim.fromValue = 0.04
        shadowAnim.toValue = 0.08
        shadowAnim.duration = 0.2
        inputsContainer.layer.add(shadowAnim, forKey: "shadowOpacity")
        inputsContainer.layer.shadowOpacity = 0.08
        
        // Animate Underline & Icon
        UIView.animate(withDuration: 0.25) {
            underline.backgroundColor = .systemBlue
            underline.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
            icon.tintColor = .systemBlue
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let isEmail = (textField == emailField)
        let underline = isEmail ? emailUnderline : passwordUnderline
        let icon = isEmail ? emailIcon : passwordIcon
        
        // Revert Container Shadow Opacity
        let shadowAnim = CABasicAnimation(keyPath: "shadowOpacity")
        shadowAnim.fromValue = 0.08
        shadowAnim.toValue = 0.04
        shadowAnim.duration = 0.2
        inputsContainer.layer.add(shadowAnim, forKey: "shadowOpacity")
        inputsContainer.layer.shadowOpacity = 0.04
        
        // Revert Underline & Icon
        UIView.animate(withDuration: 0.25) {
            underline.backgroundColor = .systemGray5
            underline.transform = .identity
            icon.tintColor = .systemGray3
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            textField.resignFirstResponder()
            SignInAction(textField)
        }
        return true
    }
}

