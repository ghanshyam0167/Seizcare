//
//  UserDataModel.swift
//  Seizcare

import Foundation

//  Enum for Gender
enum Gender: String, Codable {
    case male
    case female
    case other
    case unspecified
}

//  User Model
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var fullName: String
    var email: String
    var contactNumber: String
    var gender: Gender
    var dateOfBirth: Date
    var password: String       // Kept for model compatibility; auth is handled by Supabase Auth

    // Vitals
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
        self.id            = id
        self.fullName      = fullName
        self.email         = email
        self.contactNumber = contactNumber
        self.gender        = gender
        self.dateOfBirth   = dateOfBirth
        self.password      = password
        self.height        = height
        self.weight        = weight
        self.bloodGroup    = bloodGroup
    }

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

//  User Data Model
class UserDataModel {

    static let shared = UserDataModel()

    // In-memory session — Supabase is the only source of truth.
    // This is populated by signUpUserAsync / loginUserAsync / restoreSession.
    private(set) var currentUser: User?

    private let currentUserKey = "currentUserId"

    private init() {}

    // MARK: - Session Restore
    // Call this once from SceneDelegate/AppDelegate after the app launches.
    // Restores the authenticated session entirely from Supabase (not from a local cache).

    /// Re-authenticates the Supabase session and fetches the user profile.
    /// Call from SceneDelegate.sceneWillEnterForeground or AppDelegate.didFinishLaunching.
    func restoreSession() async {
        do {
            // Ask Supabase Auth for the current session user id
            guard let uid = await SupabaseService.shared.currentUserId() else {
                currentUser = nil
                return
            }
            let dto = try await SupabaseService.shared.fetchUser(id: uid)
            currentUser = dto?.toDomain()
            if let id = currentUser?.id {
                UserDefaults.standard.set(id.uuidString, forKey: currentUserKey)
            }
        } catch {
            print("⚠️ [UserDataModel] restoreSession failed:", error.localizedDescription)
            currentUser = nil
        }
    }

    // MARK: - Current User

    func getCurrentUser() -> User? {
        return currentUser
    }

    /// Updates the current user's profile in Supabase and refreshes the local session.
    func updateCurrentUser(_ updatedUser: User) {
        currentUser = updatedUser
        UserDefaults.standard.set(updatedUser.id.uuidString, forKey: currentUserKey)
        Task {
            do {
                try await SupabaseService.shared.updateUser(UserDTO(from: updatedUser))
            } catch {
                print("⚠️ [UserDataModel] updateCurrentUser failed:", error.localizedDescription)
            }
        }
    }

    // MARK: - Backward Compat (used by some VCs)

    /// Returns the current user in an array if set, otherwise empty — replaces the old getAllUsers().
    func getAllUsers() -> [User] {
        return currentUser.map { [$0] } ?? []
    }
}

//  - Authentication Extension
extension UserDataModel {

    // MARK: - Data Sync

    /// Refreshes all user-related data caches from Supabase in parallel.
    /// Call this immediately after a successful login or session restore.
    func syncUserData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await SeizureRecordDataModel.shared.refreshRecords() }
            group.addTask { await EmergencyContactDataModel.shared.refreshContacts() }
            group.addTask { await NotificationDataModel.shared.refreshNotifications() }
            group.addTask { await SleepDataModel.shared.refreshSleepEntries() }
        }
    }

    /// Async sign-in. Fetches user profile from Supabase after auth succeeds.
    /// Await this before navigating to protected screens.
    func loginUserAsync(email: String, password: String) async throws {
        print("[Auth] Attempting sign-in for: \(email)")

        // Step 1 — Supabase Auth. This throws if credentials are wrong OR
        // if the account email has not been confirmed yet.
        let uid: UUID
        do {
            uid = try await SupabaseService.shared.signIn(email: email, password: password)
            print("[Auth] Supabase Auth OK — uid: \(uid)")
        } catch {
            print("[Auth] Supabase signIn FAILED:", error.localizedDescription)
            // Re-throw so the VC can surface the real reason
            throw error
        }

        // Step 2 — Fetch profile row from the users table.
        let dto: UserDTO?
        do {
            dto = try await SupabaseService.shared.fetchUser(id: uid)
        } catch {
            print("[Auth] fetchUser FAILED:", error.localizedDescription)
            dto = nil   // treat as missing profile; fall through to graceful path
        }

        if let user = dto?.toDomain() {
            print("[Auth] Profile found: \(user.fullName)")
            currentUser = user
        } else {
            // Auth succeeded but no profile row exists yet (e.g. row was never
            // inserted, or the users table is empty). Build a minimal session
            // from what we know so the app still navigates correctly.
            print("[Auth] No profile row found — creating minimal session for uid \(uid)")
            let minimal = User(
                id:            uid,
                fullName:      "",
                email:         email,
                contactNumber: "",
                gender:        .unspecified,
                dateOfBirth:   Date(),
                password:      ""
            )
            currentUser = minimal
        }
        UserDefaults.standard.set(uid.uuidString, forKey: currentUserKey)
    }

    /// Legacy synchronous wrapper — kept for backward compatibility.
    /// Prefer loginUserAsync for new or refactored call sites.
    @discardableResult
    func loginUser(emailOrPhone: String, password: String) -> Bool {
        Task {
            do {
                try await loginUserAsync(email: emailOrPhone, password: password)
            } catch {
                print("⚠️ [UserDataModel] loginUser failed:", error.localizedDescription)
            }
        }
        return true   // optimistic; real result comes via currentUser being set
    }

    /// Register via Supabase Auth, insert a profile row, and establish the local session.
    /// Await this before navigating to protected screens.
    func signUpUserAsync(user: User) async throws {
        let uid = try await SupabaseService.shared.signUp(email: user.email, password: user.password)
        // Use the Supabase auth uid as the profile id so all foreign keys align.
        let profileUser = User(
            id:            uid,
            fullName:      user.fullName,
            email:         user.email,
            contactNumber: user.contactNumber,
            gender:        user.gender,
            dateOfBirth:   user.dateOfBirth,
            password:      "",
            height:        user.height,
            weight:        user.weight,
            bloodGroup:    user.bloodGroup
        )
        try await SupabaseService.shared.insertUser(UserDTO(from: profileUser))
        // Session is live — set currentUser before returning so callers can verify.
        currentUser = profileUser
        UserDefaults.standard.set(profileUser.id.uuidString, forKey: currentUserKey)
    }

    func logoutUser(completion: @escaping (Bool) -> Void) {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        Task { try? await SupabaseService.shared.signOut() }
        completion(true)
    }
}
