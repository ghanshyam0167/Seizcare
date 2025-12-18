//
//  EditProfileTableViewController.swift
//  Seizcare
//
//  Created by Student on 20/11/25.
//

import UIKit

class EditProfileTableViewController: UITableViewController {
    var user: User
    
    required init?(coder: NSCoder, user : User?) {
        guard let user = user else { return nil }
        self.user = user
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onDismiss: (() -> Void)?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var bloodGroupTextField: UITextField!
    
    @IBOutlet weak var section1CardContainer: UIView!
    @IBOutlet weak var section0CardContainer: UIView!
    let dateFormatter: DateFormatter = {
           let df = DateFormatter()
           df.dateFormat = "yyyy-MM-dd"
           return df
       }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        applyDefaultTableBackground()
        navigationController?.applyWhiteNavBar()
        [section1CardContainer, section0CardContainer].forEach {
            $0?.applyDashboardCard()
        }
        prefillUI()
        setupGenderMenu()
    }
    func prefillUI() {
           nameTextField.text = user.fullName
           emailTextField.text = user.email
           phoneTextField.text = user.contactNumber
           dobTextField.text = dateFormatter.string(from: user.dateOfBirth)
           genderButton.setTitle(user.gender.rawValue.capitalized, for: .normal)

           if let h = user.height { heightTextField.text = "\(h)" }
           if let w = user.weight { weightTextField.text = "\(w)" }
           bloodGroupTextField.text = user.bloodGroup
       }
    func setupGenderMenu() {
            let selected = user.gender

            genderButton.menu = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Male",
                         state: selected == .male ? .on : .off,
                         handler: { _ in self.setGender(.male) }),

                UIAction(title: "Female",
                         state: selected == .female ? .on : .off,
                         handler: { _ in self.setGender(.female) }),

                UIAction(title: "Other",
                         state: selected == .other ? .on : .off,
                         handler: { _ in self.setGender(.other) }),

                UIAction(title: "Unspecified",
                         state: selected == .unspecified ? .on : .off,
                         handler: { _ in self.setGender(.unspecified) })
            ])

            genderButton.showsMenuAsPrimaryAction = true
        }

    func setGender(_ gender: Gender) {
            user.gender = gender
            genderButton.setTitle(gender.rawValue.capitalized, for: .normal)
    }

    @IBAction func doneBottonTapped(_ sender: Any) {
        let updatedUser = User(
                   id: user.id,
                   fullName: nameTextField.text ?? "",
                   email: emailTextField.text ?? "",
                   contactNumber: phoneTextField.text ?? "",
                   gender: user.gender,
                   dateOfBirth: dateFormatter.date(from: dobTextField.text ?? "") ?? user.dateOfBirth,
                   password: user.password,
                   height: Double(heightTextField.text ?? ""),
                   weight: Double(weightTextField.text ?? ""),
                   bloodGroup: bloodGroupTextField.text
               )

              UserDataModel.shared.updateCurrentUser(updatedUser)
            onDismiss?()
            dismiss(animated: true)

    }
    
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
    }

}
