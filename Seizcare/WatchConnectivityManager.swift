import Foundation
import UIKit
import WatchConnectivity
import os

// MARK: - Connection Status

/// Represents every possible state of the Apple Watch connection.
enum WatchConnectionStatus {
    /// WCSession is not supported on this device (iPad / non-Apple-Watch territory)
    case notSupported
    /// WCSession is supported but no Apple Watch has been paired
    case notPaired
    /// A Watch is paired but the Seizcare Watch app is not installed on it
    case notInstalled
    /// The Watch app is installed but is not currently reachable (Watch not nearby / app not foregrounded)
    case notReachable
    /// The Watch app is installed and actively reachable
    case connected

    // MARK: Display helpers

    var title: String {
        switch self {
        case .notSupported:  return "Not Available"
        case .notPaired:     return "Not Paired"
        case .notInstalled:  return "Watch App Not Installed"
        case .notReachable:  return "Installed – Not Reachable"
        case .connected:     return "Connected"
        }
    }

    var subtitle: String {
        switch self {
        case .notSupported:  return "Apple Watch is not supported on this device."
        case .notPaired:     return "Please pair an Apple Watch with your iPhone."
        case .notInstalled:  return "Install the Seizcare app on your Apple Watch."
        case .notReachable:  return "Open the Seizcare app on your Apple Watch."
        case .connected:     return "Apple Watch is connected and ready."
        }
    }

    /// SF Symbol name for the current state
    var symbolName: String {
        switch self {
        case .notSupported:  return "applewatch.slash"
        case .notPaired:     return "applewatch"
        case .notInstalled:  return "applewatch.watchface"
        case .notReachable:  return "applewatch.radiowaves.left.and.right"
        case .connected:     return "checkmark.circle.fill"
        }
    }

    /// Accent colour matching the state severity
    var accentColor: UIColor {
        switch self {
        case .notSupported:  return .systemGray
        case .notPaired:     return .systemRed
        case .notInstalled:  return .systemOrange
        case .notReachable:  return .systemYellow
        case .connected:     return .systemGreen
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    /// Posted on the main queue whenever the WCSession activation state changes.
    static let watchSessionActivated = Notification.Name("WatchSessionActivated")
}

// MARK: - Manager

class WatchConnectivityManager: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
        print("📱 [WCM-iPhone] Initialising WatchConnectivityManager")
        if WCSession.isSupported() {
            print("📱 [WCM-iPhone] WCSession is supported — activating")
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            print("❌ [WCM-iPhone] WCSession NOT supported on this device")
        }
    }

    // MARK: - Status Checking

    /// Returns the current Watch connection status synchronously.
    /// Must be queried from the main thread (WCSession properties are @MainActor-safe).
    func checkCurrentStatus() -> WatchConnectionStatus {
        guard WCSession.isSupported() else { return .notSupported }
        let session = WCSession.default
        guard session.activationState == .activated else { return .notPaired }
        guard session.isPaired else { return .notPaired }
        guard session.isWatchAppInstalled else { return .notInstalled }
        guard session.isReachable else { return .notReachable }
        return .connected
    }

    // MARK: - Actions

    /// Opens the Apple Watch companion app on the iPhone so the user can pair or
    /// install the Watch app. Falls back silently if the URL can't be opened.
    func openWatchApp() {
        guard let url = URL(string: "itms-watchs://") else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate
    // nonisolated is required because the project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor.
    // WCSession delivers delegate callbacks on a background thread, so without nonisolated
    // Swift will crash or silently drop the call.

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if let error = error {
            print("❌ [WCM-iPhone] WCSession activation FAILED: \(error.localizedDescription)")
        } else {
            print("✅ [WCM-iPhone] WCSession activated — state: \(activationState.rawValue)")
            print("📱 [WCM-iPhone] isWatchAppInstalled: \(session.isWatchAppInstalled)")
            print("📱 [WCM-iPhone] isPaired: \(session.isPaired)")
        }
        // Notify any listening UI so it can refresh its status display.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .watchSessionActivated, object: nil)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ [WCM-iPhone] Session became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ [WCM-iPhone] Session deactivated — reactivating")
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("📨 [WCM-iPhone] Received sendMessage from Watch: \(message)")
        handleIncomingPayload(message)
    }

    /// Handles the transferUserInfo fallback (used when iPhone is in background / not reachable).
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("📦 [WCM-iPhone] Received transferUserInfo from Watch: \(userInfo)")
        handleIncomingPayload(userInfo)
    }

    // MARK: - Private

    private func handleIncomingPayload(_ payload: [String: Any]) {
        if let isEmergency = payload["emergencyAlert"] as? Bool, isEmergency {
            print("🚨 [WCM-iPhone] emergencyAlert=true — triggering countdown on main thread")
            DispatchQueue.main.async {
                EmergencyService.shared.triggerWithCountdown()
            }
            return
        }

        if let heartRate = payload["heartRate"] as? Double {
            print("💓 [WCM-iPhone] Heart Rate from Watch: \(Int(heartRate)) bpm")
        } else if let sensitivity = payload["sensitivity"] as? String {
            print("📊 [WCM-iPhone] Sensitivity from Watch: \(sensitivity)")
        } else {
            print("ℹ️ [WCM-iPhone] Unhandled payload: \(payload)")
        }
    }
}



