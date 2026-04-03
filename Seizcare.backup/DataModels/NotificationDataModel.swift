//
//  NotificationDataModel.swift
//  Seizcare
//

import Foundation

//  Notification Model
struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var title: String
    var iconName: String
    var dateTime: Date
    var description: String?

    /// Convenience init for creating new notifications (generates a new UUID).
    init(userId: UUID, title: String, iconName: String, dateTime: Date, description: String? = nil) {
        self.id          = UUID()
        self.userId      = userId
        self.title       = title
        self.iconName    = iconName
        self.dateTime    = dateTime
        self.description = description
    }

    /// Full memberwise init used by DTO → domain conversion.
    init(id: UUID, userId: UUID, title: String, iconName: String, dateTime: Date, description: String? = nil) {
        self.id          = id
        self.userId      = userId
        self.title       = title
        self.iconName    = iconName
        self.dateTime    = dateTime
        self.description = description
    }

    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Notification Data Model
class NotificationDataModel {

    static let shared = NotificationDataModel()

    private var cachedNotifications: [AppNotification] = []

    private init() {}

    // MARK: - Public Refresh (async, call from ViewControllers)

    /// Fetches notifications for the current user from Supabase and updates the cache.
    func refreshNotifications() async {
        print("🔍 [NotificationDataModel] refreshNotifications() called")
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else {
            print("⚠️ [NotificationDataModel] refresh failed: No current user ID")
            return
        }
        print("👤 [NotificationDataModel] Fetching for user: \(userId)")
        do {
            let dtos = try await SupabaseService.shared.fetchNotifications(userId: userId)
            print("✅ [NotificationDataModel] Supabase returned \(dtos.count) notifications")
            cachedNotifications = dtos.map { $0.toDomain() }
        } catch {
            print("❌ [NotificationDataModel] refreshNotifications failed:", error.localizedDescription)
        }
    }
    
    //  Public CRUD methods
    
    /// Returns all notifications (for admin/debug use)
    func getAllNotifications() -> [AppNotification] {
        return cachedNotifications
    }

    /// Returns notifications for the currently logged-in user from the local cache.
    func getNotificationsForCurrentUser() -> [AppNotification] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print(" No user is currently logged in.")
            return []
        }
        return cachedNotifications.filter { $0.userId == currentUser.id }
    }

    /// Adds a new notification for the currently logged-in user.
    ///
    /// All display data (title, icon, description) is derived automatically
    /// from the `NotificationType` enum — no raw strings required at the call site.
    ///
    /// Usage:
    /// ```swift
    /// NotificationDataModel.shared.addNotification(type: .emergencyAlert)
    /// NotificationDataModel.shared.addNotification(type: .seizureDetected(seizureType: "mild"))
    /// NotificationDataModel.shared.addNotification(type: .abnormalHeartRate(bpm: 140))
    /// ```
    func addNotification(type: NotificationType) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("Cannot add notification — no user logged in.")
            return
        }
        let newNotification = AppNotification(
            userId: currentUser.id,
            title: type.title,
            iconName: type.iconName,
            dateTime: Date(),
            description: type.description
        )
        cachedNotifications.append(newNotification)

        Task {
            print("📤 [NotificationDataModel] Inserting new notification to Supabase: \(newNotification.title)")
            do {
                try await SupabaseService.shared.insertNotification(NotificationDTO(from: newNotification))
                print("✅ [NotificationDataModel] Remote insert successful")
            } catch {
                print("❌ [NotificationDataModel] insertNotification failed:", error.localizedDescription)
            }
        }
    }
}
