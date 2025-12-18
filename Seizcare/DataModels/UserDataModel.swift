//
//  User.swift
//  SeizureDetection
//
//  Created by Diya Sharma on 10/11/25.
//

import Foundation

// MARK: - Enum for Gender
enum Gender: String, Codable {
    case male
    case female
    case other
    case unspecified
}

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var fullName: String
    var email: String
    var contactNumber: String
    var gender: Gender
    var dateOfBirth: Date
    var password: String
    
    // Vitals (Basic profile info only)
    var height: Double?
    var weight: Double?
    var bloodGroup: String?
    
    init(
        id: UUID = UUID(),
        fullName: String,
        email: String,
        contactNumber: String,
        gender: Gender,
        dateOfBirth: Date,
        password: String,
        height: Double? = nil,
        weight: Double? = nil,
        bloodGroup: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.contactNumber = contactNumber
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.password = password
        self.height = height
        self.weight = weight
        self.bloodGroup = bloodGroup
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Data Model
class UserDataModel {
    
    static let shared = UserDataModel()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    
    private var users: [User] = []
    private let currentUserKey = "currentUserId"
    private var currentUser: User?
    
    private init() {
        archiveURL = documentsDirectory
            .appendingPathComponent("users")
            .appendingPathExtension("plist")
        loadUsers()
        loadCurrentUser()
    }
    
    // MARK: - CRUD
    func addUser(_ user: User) {
        users.append(user)
        saveUsers()
    }
    
    func updateCurrentUser(_ updatedUser: User) {
        // Ensure someone is logged in
        guard let current = currentUser else { return }

        // Replace the existing user with the updated one
        if let index = users.firstIndex(where: { $0.id == current.id }) {
            users[index] = updatedUser
            currentUser = updatedUser
            saveUsers()

            // Store updated ID just to keep consistency
            UserDefaults.standard.set(updatedUser.id.uuidString, forKey: currentUserKey)
        }
    }

    
    func deleteUser(at index: Int) {
        guard users.indices.contains(index) else { return }
        users.remove(at: index)
        saveUsers()
    }
    
    func getAllUsers() -> [User] {
        return users
    }
    
    // MARK: - Private Storage Helpers
    private func loadUsers() {
        if let savedUsers = loadUsersFromDisk() {
            users = savedUsers
        } else {
            users = loadSampleUsers()
        }
    }
    
    private func loadUsersFromDisk() -> [User]? {
        guard let data = try? Data(contentsOf: archiveURL) else { return nil }
        let decoder = PropertyListDecoder()
        return try? decoder.decode([User].self, from: data)
    }
    
    private func saveUsers() {
        let encoder = PropertyListEncoder()
        let data = try? encoder.encode(users)
        try? data?.write(to: archiveURL, options: .noFileProtection)
    }
    
    private func loadSampleUsers() -> [User] {
        let user1 = User(
            id: UUID(uuidString: "A44B2A65-159A-46EF-812C-66CF308E809E")!,
            fullName: "Ghanshyam Agrawal",
            email: "ghanshyam@example.com",
            contactNumber: "+91 9876543210",
            gender: .male,
            dateOfBirth: Date(timeIntervalSince1970: 946684800), // 2000-01-01
            password: "password121",
            height: 172.0,
            weight: 68.0,
            bloodGroup: "O+"
        )
        
        let user2 = User(
            fullName: "Diya Sharma",
            email: "diya@example.com",
            contactNumber: "+91 9988776655",
            gender: .female,
            dateOfBirth: Date(timeIntervalSince1970: 883612800), // 1998-01-01
            password: "password121",
            height: 160.0,
            weight: 55.0,
            bloodGroup: "A+"
        )
        
        return [user1, user2]
    }
}

// MARK: - Authentication Extension
extension UserDataModel {
    
    func loginUser(email: String, password: String) -> Bool {
        if let user = validateUser(email: email, password: password) {
            currentUser = user
            UserDefaults.standard.set(user.id.uuidString, forKey: currentUserKey)
            return true
        }
        
        return false
    }
    
    func logoutUser(completion: @escaping (Bool) -> Void) {
        // Clear stored user data
        UserDefaults.standard.removeObject(forKey: "loggedInUser")

        completion(true)
    }

    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    private func loadCurrentUser() {
        if let userIdString = UserDefaults.standard.string(forKey: currentUserKey),
           let userId = UUID(uuidString: userIdString),
           let savedUser = users.first(where: { $0.id == userId }) {
            currentUser = savedUser
        }
    }
    
    private func validateUser(email: String, password: String) -> User? {
        return users.first(where: { $0.email == email && $0.password == password })
    }
}
