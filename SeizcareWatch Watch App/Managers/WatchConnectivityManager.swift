import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchConnectivityManager()
    
    // If emergencyAlert is triggered before activation completes, store it here
    // and send it the moment the session activates.
    private var pendingEmergency = false
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("⌚️ [WCM-Watch] WCSession activation requested")
        } else {
            print("❌ [WCM-Watch] WCSession NOT supported")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    // nonisolated needed because watchOS also has SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if let error = error {
            print("❌ [WCM-Watch] Activation failed: \(error.localizedDescription)")
            return
        }
        print("✅ [WCM-Watch] Activated — state: \(activationState.rawValue)")
        print("⌚️ [WCM-Watch] isCompanionAppInstalled: \(session.isCompanionAppInstalled)")
        print("⌚️ [WCM-Watch] isReachable: \(session.isReachable)")
        
        // Flush any emergency that was triggered before activation finished
        if activationState == .activated && pendingEmergency {
            print("🚨 [WCM-Watch] Sending queued emergency alert after activation")
            pendingEmergency = false
            dispatchEmergency()
        }
    }
    
    // MARK: - Public API
    
    func sendEmergencyAlert() {
        print("🆘 [WCM-Watch] sendEmergencyAlert() called")
        print("⌚️ [WCM-Watch] activationState: \(WCSession.default.activationState.rawValue)")
        print("⌚️ [WCM-Watch] isReachable: \(WCSession.default.isReachable)")
        print("⌚️ [WCM-Watch] isCompanionAppInstalled: \(WCSession.default.isCompanionAppInstalled)")
        
        guard WCSession.default.activationState == .activated else {
            // Not ready yet — queue and wait for activation callback
            print("⏳ [WCM-Watch] Not activated yet — queueing emergency for post-activation send")
            pendingEmergency = true
            return
        }
        
        dispatchEmergency()
    }
    
    func sendSensitivity(_ level: String) {
        sendMessage(["sensitivity": level.lowercased()])
    }
    
    func sendHeartRate(_ value: Double) {
        sendMessage(["heartRate": value])
    }
    
    // MARK: - Private helpers
    
    /// Dispatches the emergency via the best available WCSession channel.
    /// - Uses `sendMessage` when the iPhone app is reachable (foreground).
    /// - Falls back to `transferUserInfo` when not reachable — this is queued
    ///   by the system and delivered as soon as the iPhone app becomes active.
    private func dispatchEmergency() {
        guard WCSession.default.isCompanionAppInstalled else {
            print("❌ [WCM-Watch] Companion iPhone app not installed — cannot send")
            return
        }
        
        let payload: [String: Any] = ["emergencyAlert": true]
        
        if WCSession.default.isReachable {
            print("📲 [WCM-Watch] iPhone is reachable — using sendMessage")
            WCSession.default.sendMessage(payload, replyHandler: nil) { error in
                print("❌ [WCM-Watch] sendMessage failed: \(error.localizedDescription)")
                // Retry via transferUserInfo as fallback
                print("🔄 [WCM-Watch] Retrying via transferUserInfo")
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            // iPhone app is in background — transferUserInfo is queued and guaranteed
            print("📦 [WCM-Watch] iPhone not reachable — using transferUserInfo (background queue)")
            WCSession.default.transferUserInfo(payload)
        }
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isCompanionAppInstalled,
              WCSession.default.isReachable else {
            return
        }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("❌ [WCM-Watch] sendMessage failed: \(error.localizedDescription)")
        }
    }
}
