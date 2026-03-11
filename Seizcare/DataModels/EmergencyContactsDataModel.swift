//
//  EmergencyContactsDataModel.swift
//  Seizcare
//

import Foundation

//  EmergencyContact Model
struct EmergencyContact: Equatable, Codable {
    let id: UUID
    let userId: UUID
    var name: String
    var contactNumber: String

    /// Convenience init for creating new contacts (generates a new UUID).
    init(userId: UUID, name: String, contactNumber: String) {
        self.id            = UUID()
        self.userId        = userId
        self.name          = name
        self.contactNumber = contactNumber
    }

    /// Full memberwise init used by DTO → domain conversion.
    init(id: UUID, userId: UUID, name: String, contactNumber: String) {
        self.id            = id
        self.userId        = userId
        self.name          = name
        self.contactNumber = contactNumber
    }

    static func == (lhs: EmergencyContact, rhs: EmergencyContact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Emergency Contact Data Model
class EmergencyContactDataModel {

    static let shared = EmergencyContactDataModel()

    private var cachedContacts: [EmergencyContact] = []

    private init() {}

    // MARK: - Public Refresh (async, call from ViewControllers)

    /// Fetches contacts for the current user from Supabase and updates the cache.
    func refreshContacts() async {
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        do {
            let dtos = try await SupabaseService.shared.fetchContacts(userId: userId)
            cachedContacts = dtos.map { $0.toDomain() }
        } catch {
            print("⚠️ [EmergencyContactDataModel] refreshContacts failed:", error.localizedDescription)
        }
    }
    
    //  Public Methods
    
    /// Get all contacts (for debugging/admin)
    func getAllContacts() -> [EmergencyContact] {
        return cachedContacts
    }

    /// Returns contacts for the currently logged-in user from the local cache.
    func getContactsForCurrentUser() -> [EmergencyContact] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("No user logged in.")
            return []
        }
        return cachedContacts.filter { $0.userId == currentUser.id }
    }

    /// Adds a new contact for the currently logged-in user.
    func addContact(name: String, contactNumber: String) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("Cannot add contact — no user logged in.")
            return
        }
        let newContact = EmergencyContact(
            userId: currentUser.id,
            name: name,
            contactNumber: contactNumber
        )
        cachedContacts.append(newContact)

    
    //  Private Methods
    
    private func loadContacts() {
        if let savedContacts = loadContactsFromDisk() {
            contacts = savedContacts
        } else {
            contacts = loadSampleContacts()
        }
    }

    /// Deletes a contact by ID.
    func deleteContact(id: UUID) {
        cachedContacts.removeAll { $0.id == id }
        Task {
            do {
                try await SupabaseService.shared.deleteContact(id: id)
            } catch {
                print("⚠️ [EmergencyContactDataModel] deleteContact failed:", error.localizedDescription)
            }
        }
    }
}
