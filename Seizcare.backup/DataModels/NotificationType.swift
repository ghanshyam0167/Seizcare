//
//  NotificationType.swift
//  Seizcare
//
//  Defines all predefined notification types used across the app.
//  Add new cases here to extend the notification system without
//  touching any call-site logic.
//

import Foundation

// MARK: - NotificationType

enum NotificationType {

    // MARK: Cases

    /// Fired when an automatic seizure detection completes.
    /// - Parameter seizureType: The severity string (mild / moderate / severe).
    case seizureDetected(seizureType: String)

    /// Fired when the user manually logs a seizure record.
    case seizureRecorded

    /// Fired after an emergency SMS alert is successfully dispatched.
    case emergencyAlert

    /// Fired when the wearable detects an abnormal heart rate.
    /// - Parameter bpm: The measured heart rate in beats per minute.
    case abnormalHeartRate(bpm: Int)

    /// Fired when the wearable or phone detects a potential fall.
    case fallDetected

    /// Generic test/debug notification used during development.
    case testNotification

    // MARK: - Computed Properties

    /// Human-readable title shown in the notification history list.
    var title: String {
        switch self {
        case .seizureDetected:
            return "Seizure Detected"
        case .seizureRecorded:
            return "Seizure Recorded"
        case .emergencyAlert:
            return "Emergency Alert Sent"
        case .abnormalHeartRate:
            return "Abnormal Heart Rate"
        case .fallDetected:
            return "Fall Detected"
        case .testNotification:
            return "Test Notification"
        }
    }

    /// Detail text shown beneath the title. Supports dynamic values via associated values.
    var description: String {
        switch self {
        case .seizureDetected(let seizureType):
            return "A \(seizureType) seizure was automatically detected and recorded."
        case .seizureRecorded:
            return "You manually added a seizure record."
        case .emergencyAlert:
            return "An emergency alert was sent to your contacts with your current location."
        case .abnormalHeartRate(let bpm):
            return "Your heart rate reached \(bpm) bpm, which is outside the normal range."
        case .fallDetected:
            return "A potential fall was detected. If you're okay, please dismiss this alert."
        case .testNotification:
            return "This is a test notification to verify that the history screen works."
        }
    }

    /// SF Symbol name used as the notification icon.
    var iconName: String {
        switch self {
        case .seizureDetected:
            return "bolt.fill"
        case .seizureRecorded:
            return "pencil.and.outline"
        case .emergencyAlert:
            return "exclamationmark.triangle.fill"
        case .abnormalHeartRate:
            return "heart.fill"
        case .fallDetected:
            return "figure.fall"
        case .testNotification:
            return "bell.fill"
        }
    }
}
