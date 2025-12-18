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
            showAlert(message: "Please enter both email/phone and password.")
            return
        }

        debugLog("Attempting login with UserDataModel…")

        // MARK: ✨ Use your UserDataModel here
        let loginSuccess = UserDataModel.shared.loginUser(email: email, password: password)

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
        EmailOrPhNo.delegate = self
        PasswordTextField.delegate = self
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

