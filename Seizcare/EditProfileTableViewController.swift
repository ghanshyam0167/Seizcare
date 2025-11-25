//
//  EditProfileTableViewController.swift
//  Seizcare
//
//  Created by Student on 20/11/25.
//

import UIKit

class EditProfileTableViewController: UITableViewController {
    var user: User?
    
    required init?(coder: NSCoder, user : User?) {
        super.init(coder: coder)
        self.user = user
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onSave: ((User) -> Void)?

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var dobTextField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var weightTextField: UITextField!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var bloodGroupTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prefill UI
        nameTextField.text = user?.name ?? ""
        emailTextField.text = user?.email ?? ""
        phoneTextField.text = user?.phone ?? ""
        dobTextField.text = user?.dob ?? ""
        genderButton.setTitle(user?.gender ?? "Select", for: .normal)
        heightTextField.text = user?.height ?? ""
        weightTextField.text = user?.weight ?? ""
        bloodGroupTextField.text = user?.bloodGroup ?? ""
        
        // Gender menu with checkmark
        let selectedGender = user?.gender ?? ""

        let menuItems = [
            UIAction(title: "Male", state: selectedGender == "Male" ? .on : .off, handler: { _ in
                self.setGender("Male")
            }),
            UIAction(title: "Female", state: selectedGender == "Female" ? .on : .off, handler: { _ in
                self.setGender("Female")
            }),
            UIAction(title: "Other", state: selectedGender == "Other" ? .on : .off, handler: { _ in
                self.setGender("Other")
            })
        ]

        genderButton.menu = UIMenu(title: "", options: .displayInline, children: menuItems)
        genderButton.showsMenuAsPrimaryAction = true
    }

    func setGender(_ gender: String) {
        genderButton.setTitle(gender, for: .normal)
    }

    @IBAction func doneBottonTapped(_ sender: Any) {
        let updated = User(
                name: nameTextField.text ?? "",
                email: emailTextField.text ?? "",
                phone: phoneTextField.text ?? "",
                dob: dobTextField.text ?? "",
                gender: genderButton.title(for: .normal) ?? "",
                height: heightTextField.text ?? "",
                weight: weightTextField.text ?? "",
                bloodGroup: bloodGroupTextField.text ?? ""
            )

            onSave?(updated)
            navigationController?.popViewController(animated: true)

    }
    
   

}
