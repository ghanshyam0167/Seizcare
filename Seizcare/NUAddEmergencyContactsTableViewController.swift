//
//  NUAddEmergencyContactsTableViewController.swift
//  Seizcare
//
//  Created by Jasmeen Grewal on 18/02/26.
//

import UIKit
import Contacts
import ContactsUI

class NUAddEmergencyContactsTableViewController: UITableViewController, CNContactPickerDelegate {

    // MARK: - Properties
    var contacts: [EmergencyContact] = []
    private var continueButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        loadContacts()
        setupContinueButton()
        updateContinueButtonState()
    }

    // MARK: - Data Loading

    private func loadContacts() {
        contacts = EmergencyContactDataModel.shared.getContactsForCurrentUser()
        tableView.reloadData()
    }

    // MARK: - Continue Button Setup (Programmatic)

    private func setupContinueButton() {
        continueButton = UIButton(type: .system)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.setTitleColor(.lightText, for: .disabled)
        continueButton.layer.cornerRadius = 14
        continueButton.layer.masksToBounds = true
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(continueButtonTapped(_:)), for: .touchUpInside)

        // Add to the main view (on top of table view)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Add some bottom content inset so last cell isn't hidden behind button
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
    }

    // MARK: - Actions

    @IBAction func addButtonTapped(_ sender: Any) {
        // Check limit before opening picker
        if contacts.count >= 3 {
            let alert = UIAlertController(
                title: "Limit Reached",
                message: "You can only add up to 3 emergency contacts. Remove any contact first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }

        let picker = CNContactPickerViewController()
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc func continueButtonTapped(_ sender: UIButton) {
        guard !contacts.isEmpty else { return }

        // Navigate to Sensitivity screen
        let sensitivityVC = storyboard?.instantiateViewController(withIdentifier: "NUSensitivityVC") as! NUAdjustSensitivityViewController
        navigationController?.pushViewController(sensitivityVC, animated: true)
    }

    // MARK: - CNContactPickerDelegate

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {

        // --- Extract name & phone ---
        let name = "\(contact.givenName) \(contact.familyName)"
            .trimmingCharacters(in: .whitespaces)

        let phone = contact.phoneNumbers.first?.value.stringValue
            .trimmingCharacters(in: .whitespaces) ?? ""

        // ---- STEP 1: Limit to 3 ----
        if contacts.count >= 3 {
            picker.dismiss(animated: true) {
                let alert = UIAlertController(
                    title: "Limit Reached",
                    message: "You can only add up to 3 emergency contacts. Remove any contact first.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
            return
        }

        // ---- STEP 2: Duplicate check ----
        let exists = contacts.contains { existing in
            existing.name.lowercased() == name.lowercased() &&
            existing.contactNumber.replacingOccurrences(of: " ", with: "") ==
            phone.replacingOccurrences(of: " ", with: "")
        }

        if exists {
            picker.dismiss(animated: true) {
                let alert = UIAlertController(
                    title: "Already Added",
                    message: "\(name) is already in your emergency contact list.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
            return
        }

        // ---- STEP 3: Save Contact ----
        EmergencyContactDataModel.shared.addContact(
            name: name,
            contactNumber: phone
        )

        picker.dismiss(animated: true) {
            self.loadContacts()
            self.updateContinueButtonState()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! EmergencyContactsTableViewCell

        let contact = contacts[indexPath.row]
        cell.configure(with: contact)

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    // MARK: - Swipe to Delete

    override func tableView(_ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in

            let contactToDelete = self.contacts[indexPath.row]
            EmergencyContactDataModel.shared.deleteContact(id: contactToDelete.id)

            self.loadContacts()
            self.updateContinueButtonState()
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    // MARK: - Helpers

    private func updateContinueButtonState() {
        let isEnabled = !contacts.isEmpty
        continueButton?.isEnabled = isEnabled
        continueButton?.alpha = isEnabled ? 1.0 : 0.5
    }
}
