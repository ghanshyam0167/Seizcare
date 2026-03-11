//
//  NotificationDataModel.swift
//  Seizcare
//

import Foundation

// MARK: - Notification Model
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
        guard let userId = UserDataModel.shared.getCurrentUser()?.id else { return }
        do {
            let dtos = try await SupabaseService.shared.fetchNotifications(userId: userId)
            cachedNotifications = dtos.map { $0.toDomain() }
        } catch {
            print("⚠️ [NotificationDataModel] refreshNotifications failed:", error.localizedDescription)
        }
    }

    // MARK: - Public CRUD Methods

    /// Returns all notifications from the local cache.
    func getAllNotifications() -> [AppNotification] {
        return cachedNotifications
    }

    /// Returns notifications for the currently logged-in user from the local cache.
    func getNotificationsForCurrentUser() -> [AppNotification] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("⚠️ No user is currently logged in.")
            return []
        }
        return cachedNotifications.filter { $0.userId == currentUser.id }
    }

    /// Adds a new notification for the currently logged-in user.
    func addNotification(title: String, iconName: String, description: String? = nil) {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("⚠️ Cannot add notification — no user logged in.")
            return
        }
        let newNotification = AppNotification(
            userId: currentUser.id,
            title: title,
            iconName: iconName,
            dateTime: Date(),
            description: description
        )
        cachedNotifications.append(newNotification)

        Task {
            do {
                try await SupabaseService.shared.insertNotification(NotificationDTO(from: newNotification))
            } catch {
                print("⚠️ [NotificationDataModel] insertNotification failed:", error.localizedDescription)
            }
        }
    }
}
