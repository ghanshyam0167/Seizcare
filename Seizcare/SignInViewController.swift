//
//  SignInViewController.swift
//  Seizcare
//

import UIKit

class SignInViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var EmailOrPhNo: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!

    // MARK: - Sign In Action
    @IBAction func SignInAction(_ sender: Any) {
        let email = EmailOrPhNo.text ?? ""
        let password = PasswordTextField.text ?? ""

        debugLog("User entered → Email: \(email), Password: \(password)")

        // Empty validation
        if email.isEmpty || password.isEmpty {
            showAlert(message: "Please enter email or phone and password.")
            return
        }

        debugLog("Attempting login with UserDataModel…")

        // MARK: ✨ Use your UserDataModel here
        let loginSuccess = UserDataModel.shared.loginUser(emailOrPhone: email, password: password)

        if loginSuccess {
            debugLog("Login SUCCESS → UserDataModel accepted credentials.")
            // Go directly to Dashboard for existing users (skip onboarding)
            let dashboardStoryboard = UIStoryboard(name: "Dashboard", bundle: nil)
            if let dashboardVC = dashboardStoryboard.instantiateInitialViewController() {
                let navController = UINavigationController(rootViewController: dashboardVC)
                if let scene = view.window?.windowScene,
                   let sceneDelegate = scene.delegate as? UIWindowSceneDelegate,
                   let window = sceneDelegate.window ?? view.window {
                    let transition = CATransition()
                    transition.duration = 0.3
                    transition.type = .push
                    transition.subtype = .fromRight
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.layer.add(transition, forKey: kCATransition)
                    window.rootViewController = navController
                }
            }
        } else {
            debugLog("Login FAILED → No matching user in stored users.")
            showAlert(message: "Invalid email or password.")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        EmailOrPhNo.delegate = self
        PasswordTextField.delegate = self
        PasswordTextField.isSecureTextEntry = true
        
        navigationController?.applyWhiteNavBar()
        // Hide back button
        navigationItem.setHidesBackButton(true, animated: false)
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToNextScreen" {
            if let nextVC = segue.destination as? DisclaimerViewController {
                // Passing the CURRENT LOGGED-IN USER
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == EmailOrPhNo {
            PasswordTextField.becomeFirstResponder()
        } else if textField == PasswordTextField {
            textField.resignFirstResponder()
            SignInAction(textField) // trigger sign in
        }
        return true
    }

}

