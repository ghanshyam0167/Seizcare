//
//  SignUpTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit



class SignUpTableViewController: UITableViewController {

    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var dobField: UITextField!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    private var selectedDOB: Date?
       private var selectedGender: Gender = .unspecified

       let datePicker = UIDatePicker()

       // MARK: - View Lifecycle
       override func viewDidLoad() {
           super.viewDidLoad()
           setupDOBPicker()
       }

       // MARK: - Date Picker Setup
       func setupDOBPicker() {
           dobField.inputView = datePicker
           datePicker.preferredDatePickerStyle = .wheels
           datePicker.datePickerMode = .date
           datePicker.maximumDate = Date()

           let toolbar = UIToolbar()
           toolbar.sizeToFit()
           toolbar.items = [
               UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneDOB))
           ]
           dobField.inputAccessoryView = toolbar
       }

       @objc func doneDOB() {
           let formatter = DateFormatter()
           formatter.dateFormat = "dd-MM-yyyy"
           dobField.text = formatter.string(from: datePicker.date)
           selectedDOB = datePicker.date
           view.endEditing(true)
       }

       // MARK: - Gender Selection
       @IBAction func genderTapped(_ sender: UIButton) {
           let alert = UIAlertController(title: "Select Gender", message: nil, preferredStyle: .actionSheet)

           alert.addAction(UIAlertAction(title: "Male", style: .default, handler: { _ in
               self.genderButton.setTitle("Male", for: .normal)
               self.selectedGender = .male
           }))

           alert.addAction(UIAlertAction(title: "Female", style: .default, handler: { _ in
               self.genderButton.setTitle("Female", for: .normal)
               self.selectedGender = .female
           }))

           alert.addAction(UIAlertAction(title: "Other", style: .default, handler: { _ in
               self.genderButton.setTitle("Other", for: .normal)
               self.selectedGender = .other
           }))

           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

           present(alert, animated: true)
       }

       // MARK: - Create Account
       @IBAction func createAccountTapped(_ sender: UIButton) {

           let fullName = fullNameField.text ?? ""
           let email = emailField.text ?? ""
           let phone = phoneField.text ?? ""
           let password = passwordField.text ?? ""
           let gender = selectedGender
           let dob = selectedDOB

           // -------------------------
           // Validation
           // -------------------------
           if fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || dob == nil {
               showAlert("Please fill in all fields.")
               return
           }

           if UserDataModel.shared.getAllUsers().contains(where: { $0.email == email }) {
               showAlert("An account with this email already exists.")
               return
           }

           // -------------------------
           // Create User
           // -------------------------
           let newUser = User(
               fullName: fullName,
               email: email,
               contactNumber: phone,
               gender: gender,
               dateOfBirth: dob!,
               password: password
           )

           UserDataModel.shared.addUser(newUser)
           let loginSuccess = UserDataModel.shared.loginUser(email: email, password: password)
               print("Auto-login status → \(loginSuccess)")

           // Navigate after signup
           performSegue(withIdentifier: "goToSignupSuccess", sender: self)
       }

       // MARK: - Alert Helper
       func showAlert(_ msg: String) {
           let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default))
           present(alert, animated: true)
       }

       // MARK: - Navigation
       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "goToSignupSuccess" {
               if let nextVC = segue.destination as? DisclaimerViewController {
                   nextVC.receivedEmail = emailField.text ?? ""
                   nextVC.receivedPassword = passwordField.text ?? ""
               }
           }
       }
   }
