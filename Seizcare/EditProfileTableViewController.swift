//
//  EditProfileTableViewController.swift
//  Seizcare
//
//  Created by Student on 20/11/25.
//

import UIKit
import PhotosUI

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
    @IBOutlet weak var profileImageView: UIImageView!
    
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
        setupFieldPickers()
        setupProfileImage()
    }

    // MARK: - Profile Image

    private func setupProfileImage() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        // Load saved photo
        if let saved = ProfilePhotoManager.shared.load() {
            profileImageView.image = saved
        }
    }

    @IBAction func changePhotoTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Field Pickers

    private func setupFieldPickers() {
        // Make fields non-editable, use tap gestures instead
        let pickerFields: [(UITextField, Selector)] = [
            (dobTextField, #selector(openDOBPicker)),
            (heightTextField, #selector(openHeightPicker)),
            (weightTextField, #selector(openWeightPicker)),
            (bloodGroupTextField, #selector(openBloodGroupPicker))
        ]

        for (field, action) in pickerFields {
            field.inputView = UIView()  // prevent keyboard
            field.tintColor = .clear    // hide cursor
            let tap = UITapGestureRecognizer(target: self, action: action)
            field.addGestureRecognizer(tap)
            field.isUserInteractionEnabled = true
        }
    }

    @objc private func openDOBPicker() {
        let current = dateFormatter.date(from: dobTextField.text ?? "") ?? user.dateOfBirth

        let sheet = SeizPickerSheet.datePicker(
            title: "Date of Birth",
            mode: .date,
            style: .inline,
            current: current,
            maximumDate: Date()
        ) { [weak self] selectedDate in
            guard let self else { return }
            self.dobTextField.text = self.dateFormatter.string(from: selectedDate)
        }
        present(sheet, animated: true)
    }

    @objc private func openHeightPicker() {
        let current = Double(heightTextField.text ?? "") ?? user.height ?? 170
        let sheet = SeizPickerSheet.numericPicker(
            title: "Height",
            unit: "cm",
            range: 100...250,
            step: 1,
            current: current
        ) { [weak self] value in
            self?.heightTextField.text = "\(Int(value))"
        }
        present(sheet, animated: true)
    }

    @objc private func openWeightPicker() {
        let current = Double(weightTextField.text ?? "") ?? user.weight ?? 65
        let sheet = SeizPickerSheet.numericPicker(
            title: "Weight",
            unit: "kg",
            range: 20...200,
            step: 1,
            current: current
        ) { [weak self] value in
            self?.weightTextField.text = "\(Int(value))"
        }
        present(sheet, animated: true)
    }

    @objc private func openBloodGroupPicker() {
        let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
        let sheet = SeizPickerSheet.optionPicker(
            title: "Blood Group",
            options: bloodGroups,
            selected: bloodGroupTextField.text
        ) { [weak self] selected in
            self?.bloodGroupTextField.text = selected
        }
        present(sheet, animated: true)
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

// MARK: - PHPickerViewControllerDelegate

extension EditProfileTableViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let self, let photo = image as? UIImage else { return }
            DispatchQueue.main.async {
                self.profileImageView.image = photo
                ProfilePhotoManager.shared.save(photo)
            }
        }
    }
}
