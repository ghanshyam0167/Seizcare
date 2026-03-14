import Foundation
import WatchConnectivity
import os
import Combine

extension Notification.Name {
    static let didReceiveSleepData = Notification.Name("didReceiveSleepData")
}

class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    
    static let shared = WatchConnectivityManager()
    
    @Published var heartRate: Double?
    @Published var spo2: Double?
    @Published var sleepHours: Double?
    
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
        
        var hrValue: Double = 0
        var spo2Value: Double = 0
        var sleepValue: Double = 0
        var foundHealthData = false
        
        if let heartRate = payload["heartRate"] as? Double {
            hrValue = heartRate
            foundHealthData = true
            print("📥 [WCM-iPhone] Received heart rate data from Watch: \(Int(heartRate)) BPM")
            DispatchQueue.main.async { self.heartRate = heartRate }
        }
        if let spo2 = payload["spo2"] as? Double {
            spo2Value = spo2
            foundHealthData = true
            DispatchQueue.main.async { self.spo2 = spo2 }
        }
        if let sleepHours = payload["sleepHours"] as? Double {
            sleepValue = sleepHours
            foundHealthData = true
            print("📥 [WCM-iPhone] Received sleep data from Watch: \(String(format: "%.1f", sleepHours)) hrs")
            // Update the legacy property just in case
            DispatchQueue.main.async { self.sleepHours = sleepHours }
            // Update the new HealthDataManager for real-time UI refresh
            HealthDataManager.shared.updateSleepData(hours: sleepHours)
            
            // Post notification for UIKit Dashboard
            print("📣 [WCM-iPhone] Posting NotificationCenter broadcast: didReceiveSleepData")
            NotificationCenter.default.post(name: .didReceiveSleepData, object: nil, userInfo: ["sleepHours": sleepHours])
        }
        
        if foundHealthData {
            print("📲 [WCM-iPhone] Received Health Data → HR: \(hrValue), SpO2: \(spo2Value), Sleep: \(sleepValue)")
        }
        
        if let sensitivity = payload["sensitivity"] as? String {
            print("📊 [WCM-iPhone] Sensitivity from Watch: \(sensitivity)")
        } else if payload["emergencyAlert"] == nil && payload["heartRate"] == nil && !foundHealthData {
            print("ℹ️ [WCM-iPhone] Unhandled payload: \(payload)")
        }
    }
}



