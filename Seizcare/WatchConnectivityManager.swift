import Foundation
import WatchConnectivity
import os

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
    
    // MARK: - WCSessionDelegate Methods
    // nonisolated is required because the project uses SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
    // WCSession delivers delegate callbacks on a background thread, so without nonisolated
    // Swift will crash or silently drop the call.
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ [WCM-iPhone] WCSession activation FAILED: \(error.localizedDescription)")
            return
        }
        print("✅ [WCM-iPhone] WCSession activated — state: \(activationState.rawValue)")
        print("📱 [WCM-iPhone] isWatchAppInstalled: \(session.isWatchAppInstalled)")
        print("📱 [WCM-iPhone] isPaired: \(session.isPaired)")
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
    
    /// Handles the transferUserInfo fallback (used when iPhone is in background / not reachable)
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("📦 [WCM-iPhone] Received transferUserInfo from Watch: \(userInfo)")
        handleIncomingPayload(userInfo)
    }
    
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



