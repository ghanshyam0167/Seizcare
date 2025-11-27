//
//  EmergencyContacts.swift
//  SeizureDetection
//
//  Created by Diya Sharma on 10/11/25.
//

import Foundation

// MARK: - EmergencyContact Model
struct EmergencyContact: Equatable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var contactNumber: String
    
    init(userId: UUID,  name: String, contactNumber: String) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.contactNumber = contactNumber
    }
    
    static func ==(lhs: EmergencyContact, rhs: EmergencyContact) -> Bool {
        return lhs.id == rhs.id
    }
}

class EmergencyContactDataModel {
    
    static let shared = EmergencyContactDataModel()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    
    private var contacts: [EmergencyContact] = []
    
    private init() {
        archiveURL = documentsDirectory
            .appendingPathComponent("emergencyContacts")
            .appendingPathExtension("plist")
        loadContacts()
    }
    
    // MARK: - Public Methods
    
    /// Get all contacts (for debugging/admin)
    func getAllContacts() -> [EmergencyContact] {
        return contacts
    }
    
    /// Get all contacts for the currently logged-in user
    func getContactsForCurrentUser() -> [EmergencyContact] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("⚠️ No user logged in.")
            return []
        }
        return contacts.filter { $0.userId == currentUser.id }
    }
    
    /// Add a new contact for the currently logged-in user
    func addContact(name: String, contactNumber: String) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("⚠️ Cannot add contact — no user logged in.")
            return
        }
        
        let newContact = EmergencyContact(
            userId: currentUser.id,
            name: name,
            contactNumber: contactNumber
        )
        
        contacts.append(newContact)
        saveContacts()
    }
        
    func deleteContact(id: UUID) {
        contacts.removeAll { $0.id == id }
        saveContacts()
    }

    
    // MARK: - Private Methods
    
    private func loadContacts() {
        if let savedContacts = loadContactsFromDisk() {
            contacts = savedContacts
        } else {
            contacts = loadSampleContacts()
        }
    }
    
    private func loadContactsFromDisk() -> [EmergencyContact]? {
        guard let codedContacts = try? Data(contentsOf: archiveURL) else { return nil }
        let propertyListDecoder = PropertyListDecoder()
        return try? propertyListDecoder.decode([EmergencyContact].self, from: codedContacts)
    }
    
    private func saveContacts() {
        let propertyListEncoder = PropertyListEncoder()
        let codedContacts = try? propertyListEncoder.encode(contacts)
        try? codedContacts?.write(to: archiveURL, options: .noFileProtection)
    }
    
    private func loadSampleContacts() -> [EmergencyContact] {
        // Attach sample contacts to first available user if exists
        let sampleUserId = UserDataModel.shared.getAllUsers().first?.id ?? UUID()
        
        let contact1 = EmergencyContact(userId: sampleUserId, name: "Mom", contactNumber: "+91 9876543210")
        let contact2 = EmergencyContact(userId: sampleUserId, name: "Doctor", contactNumber: "+91 9988776655")
        let contact3 = EmergencyContact(userId: sampleUserId, name: "Friend", contactNumber: "+91 9123456789")
        return [contact1, contact2, contact3]
    }
}
