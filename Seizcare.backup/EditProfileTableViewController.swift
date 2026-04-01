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
    
    /// Holds the image the user just picked so it survives until the upload finishes.
    private var selectedProfileImage: UIImage?
    
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
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        // Load from Supabase URL — falls back to placeholder automatically
        profileImageView.load(urlString: user.avatarUrl)
    }

    @IBAction func changePhotoTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Change Profile Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.presentPHPicker()
        })
        
        if user.avatarUrl != nil {
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.removePhoto()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentPHPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func removePhoto() {
        self.user.avatarUrl = nil
        self.profileImageView.load(urlString: nil)
        UserDataModel.shared.updateAvatarURL("") // Pass empty string to clear in DB
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
                   bloodGroup: bloodGroupTextField.text,
                   avatarUrl: user.avatarUrl   // preserve avatar URL through edit
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

// MARK: - Photo Picker Delegates

extension EditProfileTableViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // PHPicker (Library)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            guard let self, let raw = image as? UIImage else { return }
            self.processAndUpload(raw)
        }
    }

    // ImagePicker (Camera)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        guard let raw = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
        processAndUpload(raw)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    private func processAndUpload(_ raw: UIImage) {
        // 1. Resize + compress
        let resized = raw.resized(toMaxDimension: 512)
        guard let jpeg = resized.jpegData(compressionQuality: 0.7) else { return }

        // 2. Store temp reference so the image survives navigation/layout events
        selectedProfileImage = resized

        // 3. Show immediately — cancels any in-flight remote load (cross-dissolve fade)
        DispatchQueue.main.async {
            self.profileImageView.setImmediately(resized)
        }

        guard let userId = self.user.id as UUID? else { return }

        Task { @MainActor in
            do {
                // 4. Upload in background after UI is already updated
                let url = try await SupabaseService.shared.uploadAvatar(userId: userId, imageData: jpeg)
                UIImageView.bustCache(for: url)
                
                // 5. Save URL on the model
                self.user.avatarUrl = url
                self.selectedProfileImage = nil  // upload confirmed — no need for temp
                UserDataModel.shared.updateAvatarURL(url)
                print("✅ [EditProfile] Avatar uploaded: \(url)")
            } catch {
                let alert = UIAlertController(title: "Upload Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                // Revert to the last known good Supabase photo on error
                self.selectedProfileImage = nil
                self.profileImageView.load(urlString: self.user.avatarUrl)
            }
        }
    }
}

// MARK: - UIImage resize helper

private extension UIImage {
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
