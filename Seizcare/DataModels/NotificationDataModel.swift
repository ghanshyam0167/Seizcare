//
//  NotificationDataModel.swift
//  Seizcare
//
//  Created by Diya Sharma on 25/11/25.
//

import Foundation

//Notification Model
struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var title: String
    var iconName: String
    var dateTime: Date
    var description: String?
    
    init(userId: UUID, title: String, iconName: String, dateTime: Date, description: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.title = title
        self.iconName = iconName
        self.dateTime = dateTime
        self.description = description
    }
    
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

class NotificationDataModel {
    
    // Single instance
    static let shared = NotificationDataModel()
    
    // File path for storage
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let archiveURL: URL
    
    // In memory store
    private var notifications: [AppNotification] = []
    
    //Init
    private init() {
        archiveURL = documentsDirectory
            .appendingPathComponent("notifications")
            .appendingPathExtension("plist")
        loadNotifications()
    }
    
    // MARK: - Public CRUD methods
    
    /// Returns all notifications (for admin/debug use)
    func getAllNotifications() -> [AppNotification] {
        return notifications
    }
    
    /// Returns notifications for the currently logged-in user
    func getNotificationsForCurrentUser() -> [AppNotification] {
        guard let currentUser = UserDataModel.shared.getCurrentUser() else {
            print("⚠️ No user is currently logged in.")
            return []
        }
        return notifications.filter { $0.userId == currentUser.id }
    }
        
    /// Adds a new notification for the currently logged-in user
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
        
        notifications.append(newNotification)
        saveNotifications()
    }
        
    //Private helpers
    
    private func loadNotifications() {
        if let savedNotifications = loadNotificationsFromDisk() {
            notifications = savedNotifications
        } else {
            notifications = loadSampleNotifications()
        }
    }
    
    private func loadNotificationsFromDisk() -> [AppNotification]? {
        guard let data = try? Data(contentsOf: archiveURL) else { return nil }
        let decoder = PropertyListDecoder()
        return try? decoder.decode([AppNotification].self, from: data)
    }
    
    private func saveNotifications() {
        let encoder = PropertyListEncoder()
        let data = try? encoder.encode(notifications)
        try? data?.write(to: archiveURL, options: .noFileProtection)
    }
    
    private func loadSampleNotifications() -> [AppNotification] {
        
        let sampleUserId = UserDataModel.shared.getAllUsers().first?.id ?? UUID()
        
        var samples: [AppNotification] = []
        let now = Date()
        
        func make(_ title: String, _ icon: String, _ offset: TimeInterval, _ desc: String) {
            samples.append(
                AppNotification(
                    userId: sampleUserId,
                    title: title,
                    iconName: icon,
                    dateTime: now.addingTimeInterval(offset),
                    description: desc
                )
            )
        }
        
        //  15 Sample Notifications 
        
        // Today
        make("Seizure Alert", "bell.fill", -60 * 10, "Strong seizure detected. Contacts notified.")
        make("High Heart Rate", "waveform.path.ecg", -60 * 30, "Your BPM is above the safe range.")
        make("Low SpO₂ Level", "heart.text.square.fill", -60 * 50, "SpO₂ dropped below 90%.")
        
        // Yesterday
        make("Seizure Alert", "exclamationmark.triangle.fill", -3600 * 5, "Mild seizure detected.")
        make("High Heart Rate", "waveform.path.ecg", -3600 * 6, "Unusual heart rate spike recorded.")
        make("Low SpO₂ Level", "heart.fill", -3600 * 7, "SpO₂ fluctuating. Please relax.")
        make("Seizure Alert", "bell.fill", -3600 * 8, "Emergency notified automatically.")
        
        // 2 days ago
        make("High Heart Rate", "waveform.path.ecg", -3600 * 26, "Heart rate above normal range.")
        make("Seizure Alert", "exclamationmark.triangle.fill", -3600 * 28, "Seizure detected.")
        make("Low SpO₂ Level", "heart.text.square.fill", -3600 * 30, "Oxygen saturation low.")
        
        // 3 days ago
        make("Seizure Alert", "bell.fill", -3600 * 50, "Seizure detected during sleep.")
        make("High Heart Rate", "waveform.path.ecg", -3600 * 52, "Sudden BPM spike detected.")
        
        // 4 days ago
        make("Weekly Health Summary", "chart.bar.xaxis", -3600 * 80, "Summary available for last week.")
        make("Low SpO₂ Level", "heart.text.square.fill", -3600 * 82, "Oxygen dips recorded.")
        make("Seizure Alert", "exclamationmark.triangle.fill", -3600 * 84, "Short seizure event detected.")
        
        return samples
    }

}

