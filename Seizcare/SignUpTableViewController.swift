//
//  SignUpTableViewController.swift
//  Seizcare
//
//  Created by Student on 24/11/25.
//

import UIKit


class SignUpTableViewController: UITableViewController {

    @IBOutlet weak var section1CardContainer: UIView!
    @IBOutlet weak var section0CardContainer: UIView!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var dobField: UITextField!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    private var selectedGender: Gender = .male
    @IBOutlet weak var confirmPasswordField: UITextField!
    
       let datePicker = UIDatePicker()
    
    private func configureTextFields() {

        // Full Name
        fullNameField.keyboardType = .default
        fullNameField.textContentType = .name
        fullNameField.autocapitalizationType = .words
        fullNameField.autocorrectionType = .no

        // Email
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .emailAddress
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no

        // Phone
        phoneField.keyboardType = .numberPad
        phoneField.textContentType = .telephoneNumber

        // Password
        passwordField.isSecureTextEntry = true
        passwordField.textContentType = .newPassword
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no

        // Confirm Password
        confirmPasswordField.isSecureTextEntry = true
        confirmPasswordField.textContentType = .password
        confirmPasswordField.autocapitalizationType = .none
        confirmPasswordField.autocorrectionType = .no
    }


       // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        
        [section0CardContainer, section1CardContainer].forEach { $0.applyDashboardCard() }
        
        setupGenderMenu()
        configureDatePickerForDOB()
        configureTextFields()

        genderButton.setTitle(selectedGender.rawValue.capitalized, for: .normal)

        tableView.allowsSelection = false
        tableView.allowsMultipleSelection = false
        
        // Custom Navigation: Hide default back button & add footer
        navigationItem.setHidesBackButton(true, animated: false)
        self.title = "Sign Up"
        setupSignInFooter()
    }
    
    // MARK: - Custom Footer (Sign In)
    private func setupSignInFooter() {
        let FooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 60))
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Already have an account?"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        
        let button = UIButton(type: .system)
        button.setTitle("Sign In", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(backToSignIn), for: .touchUpInside)
        
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(button)
        
        FooterView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: FooterView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: FooterView.centerYAnchor)
        ])
        
        tableView.tableFooterView = FooterView
    }

    @objc private func backToSignIn() {
        navigationController?.popViewController(animated: true)
    }


    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private func configureInitialUI() {
           // set initial gender button title (default male)
           genderButton.setTitle(selectedGender.rawValue.capitalized, for: .normal)
           // ensure button shows menu on tap
           genderButton.showsMenuAsPrimaryAction = true
       }
    private func setupGenderMenu() {
            // Use current selectedGender to mark the .on state
            let selected = selectedGender

            genderButton.menu = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Male",
                         state: selected == .male ? .on : .off,
                         handler: { [weak self] _ in self?.setGender(.male) }),

                UIAction(title: "Female",
                         state: selected == .female ? .on : .off,
                         handler: { [weak self] _ in self?.setGender(.female) }),

                UIAction(title: "Other",
                         state: selected == .other ? .on : .off,
                         handler: { [weak self] _ in self?.setGender(.other) }),

                UIAction(title: "Unspecified",
                         state: selected == .unspecified ? .on : .off,
                         handler: { [weak self] _ in self?.setGender(.unspecified) })
            ])
        genderButton.showsMenuAsPrimaryAction = true

        }

        private func setGender(_ gender: Gender) {
            selectedGender = gender
            genderButton.setTitle(gender.rawValue.capitalized, for: .normal)
            // rebuild the menu so checkmarks update
            setupGenderMenu()
        }
    private func configureDatePickerForDOB() {
           if #available(iOS 13.4, *) {
               datePicker.preferredDatePickerStyle = .wheels
           }
           datePicker.datePickerMode = .date

           // Optional: set reasonable range (last 100 years → today)
           let calendar = Calendar.current
           if let min = calendar.date(byAdding: .year, value: -100, to: Date()) {
               datePicker.minimumDate = min
           }
           datePicker.maximumDate = Date()

           // connect picker as inputView for dobField
           dobField.inputView = datePicker

           // toolbar with done button for the picker
           let toolbar = UIToolbar()
           toolbar.sizeToFit()
           let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dobDoneTapped))
           let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
           toolbar.setItems([spacer, done], animated: false)
           dobField.inputAccessoryView = toolbar
       }
    @objc private func dobDoneTapped() {
            let selectedDate = datePicker.date
            dobField.text = dateFormatter.string(from: selectedDate)
            dobField.resignFirstResponder()
        }

       // MARK: - Create Account
       @IBAction func createAccountTapped(_ sender: UIButton) {
           guard validatePasswords() else {
                   return
               }

           let fullName = fullNameField.text ?? ""
           let email = emailField.text ?? ""
           let phone = phoneField.text ?? ""
           let password = passwordField.text ?? ""
           let gender = selectedGender
           let dobString = dobField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

           // -------------------------
           // Validation
           // -------------------------
        // -------------------------
        // Validation
        // -------------------------
        
        // 1. Name (Simple non-empty check)
        if fullName.isEmpty {
            showAlert("Please enter your full name.")
            return
        }
        
        // 2. Email (Regex)
        if email.isEmpty || !isValidEmail(email) {
            showAlert("Please enter a valid email address.")
            return
        }
        
        // 3. Phone (10 digits)
        if phone.isEmpty || !isValidPhone(phone) {
            showAlert("Please enter a valid 10-digit phone number.")
            return
        }
        
        // 4. Date of Birth
        if dobString.isEmpty {
            showAlert("Please enter your date of birth.")
            return
        }
    

           guard let dobDate = dateFormatter.date(from: dobString) else {
                       showAlert("Please enter date of birth in format yyyy-MM-dd.")
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
               dateOfBirth: dobDate,
               password: password
           )

           UserDataModel.shared.addUser(newUser)
           let loginSuccess = UserDataModel.shared.loginUser(emailOrPhone: email, password: password)
               print("Auto-login status → \(loginSuccess)")

           // Navigate after signup
           performSegue(withIdentifier: "goToSignupSuccess", sender: self)
       }
    // MARK: - Validate Password
    
    func validatePasswords() -> Bool {
        guard let password = passwordField.text,
              let confirmPassword = confirmPasswordField.text else {
            return false
        }

        if password.isEmpty || confirmPassword.isEmpty {
            showAlert("Please fill in both password fields.")
            return false
        }

        if password.count < 6 {
            showAlert("Password must be at least 6 characters long.")
            return false
        }

        if password != confirmPassword {
            showAlert("Password and Confirm Password do not match.")
            return false
        }

        return true
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
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }
    
    // MARK: - Validation Helpers
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^[0-9]{10}$"
        let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
   }
