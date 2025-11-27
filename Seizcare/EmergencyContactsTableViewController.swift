//
//  EmergencyContactsTableViewController.swift
//  Seizcare
//
//  Created by Student on 21/11/25.
//

import UIKit
import Contacts
import ContactsUI



class EmergencyContactsTableViewController: UITableViewController, CNContactPickerDelegate {

    
    var contacts: [EmergencyContact] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        loadContacts()

    }
    private func loadContacts() {
           contacts = EmergencyContactDataModel.shared.getContactsForCurrentUser()
           tableView.reloadData()
       }

    // MARK: - Table view data source

    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        let picker = CNContactPickerViewController()
            picker.delegate = self
            present(picker, animated: true)
    }
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
                    message: "You can only add up to 3 emergency contacts.Remove any contact first.",
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
        }
    }




    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contacts.count
    }
    
    override func tableView(_ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            
            let contactToDelete = self.contacts[indexPath.row]
            EmergencyContactDataModel.shared.deleteContact(id: contactToDelete.id)

            self.loadContacts()
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80   
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! EmergencyContactsTableViewCell

        let contact = contacts[indexPath.row]
        cell.configure(with: contact)

        return cell
    }


    

}
