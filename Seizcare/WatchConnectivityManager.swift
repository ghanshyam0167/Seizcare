import Foundation
import UIKit
import WatchConnectivity
import os
import Combine

// MARK: - Connection Status

enum WatchConnectionStatus {
    case notSupported
    case notPaired
    case notInstalled
    case notReachable
    case connected

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

    var symbolName: String {
        switch self {
        case .notSupported:  return "applewatch.slash"
        case .notPaired:     return "applewatch"
        case .notInstalled:  return "applewatch.watchface"
        case .notReachable:  return "applewatch.radiowaves.left.and.right"
        case .connected:     return "checkmark.circle.fill"
        }
    }

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

// MARK: - Notification Names

extension Notification.Name {
    static let didReceiveSleepData = Notification.Name("didReceiveSleepData")
    static let watchSessionActivated = Notification.Name("WatchSessionActivated")
}

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var sensitivity: String {
        didSet {
            UserDefaults.standard.set(sensitivity, forKey: "sensitivity")
            WatchConnectivityManager.shared.sendApplicationContext(sensitivity: sensitivity)
        }
    }

    private init() {
        self.sensitivity = UserDefaults.standard.string(forKey: "sensitivity") ?? "Medium"
    }
    
    func updateSensitivity(fromWatch newValue: String) {
        let validValues = ["Low", "Medium", "High", "low", "medium", "high"]
        guard validValues.contains(newValue.lowercased()) else { return }
        
        DispatchQueue.main.async {
            self.sensitivity = newValue.capitalized
        }
    }
}

// MARK: - Manager

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
    
    /// Sends the current sensitivity setting to the Apple Watch via Application Context
    func sendApplicationContext(sensitivity: String) {
        guard WCSession.isSupported() else {
            print("⚠️ [WCM-iPhone] Cannot send context: WCSession not supported")
            return
        }
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            print("⚠️ [WCM-iPhone] Cannot send context: WCSession activationState is \(session.activationState.rawValue)")
            return
        }
        
        guard session.isWatchAppInstalled else {
            print("⚠️ [WCM-iPhone] Cannot send context: Watch app is not installed")
            return
        }
        
        
        let context = ["sensitivity": sensitivity]
        do {
            try session.updateApplicationContext(context)
            print("📱 [WCM-iPhone] Sent application context successfully: \(context)")
            printDebugStatus()
        } catch {
            print("❌ [WCM-iPhone] Failed to update application context: \(error.localizedDescription)")
            printDebugStatus()
        }
    }
    
    /// Prints a comprehensive console debug block for WCSession status
    func printDebugStatus() {
        print("================================")
        print("📱 [iPhone Debug] WCSession Status:")
        print("- Supported: \(WCSession.isSupported())")
        if WCSession.isSupported() {
            let session = WCSession.default
            print("- Activation State: \(session.activationState.rawValue)")
            print("- Paired: \(session.isPaired)")
            print("- Watch App Installed: \(session.isWatchAppInstalled)")
            print("- Reachable (Foreground): \(session.isReachable)")
            print("- Current Sent Context: \(session.applicationContext)")
            print("- Current Received Context: \(session.receivedApplicationContext)")
        }
        print("- Current SettingsManager Sensitivity: \(SettingsManager.shared.sensitivity)")
        print("================================")
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
        Task { @MainActor in
            self.handleIncomingPayload(message)
        }
    }

    /// Handles the transferUserInfo fallback (used when iPhone is in background / not reachable).
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        print("📦 [WCM-iPhone] Received transferUserInfo from Watch: \(userInfo)")
        Task { @MainActor in
            self.handleIncomingPayload(userInfo)
        }
    }

    /// Handles received application context (two-way sync from watch)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("🔄 [WCM-iPhone] Received application context from Watch: \(applicationContext)")
        Task { @MainActor in
            self.handleIncomingPayload(applicationContext)
            WatchConnectivityManager.shared.printDebugStatus()
        }
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
            DispatchQueue.main.async { self.sleepHours = sleepHours }
            HealthDataManager.shared.updateSleepData(hours: sleepHours)
            print("📣 [WCM-iPhone] Posting NotificationCenter broadcast: didReceiveSleepData")
            NotificationCenter.default.post(name: .didReceiveSleepData, object: nil, userInfo: ["sleepHours": sleepHours])
            // Update detection context with new sleep data
            SeizureDetectionManager.shared.updateContext(sleepHours: sleepHours)
        }
        
        if foundHealthData {
            print("📲 [WCM-iPhone] Received Health Data → HR: \(hrValue), SpO2: \(spo2Value), Sleep: \(sleepValue)")
        }
        
        if let sensitivity = payload["sensitivity"] as? String {
            print("📊 [WCM-iPhone] Sensitivity from Watch: \(sensitivity)")
            SettingsManager.shared.updateSensitivity(fromWatch: sensitivity)
            // Sync sensitivity level to detection context
            if let level = SensitivityLevel(rawValue: sensitivity.lowercased()) {
                SeizureDetectionManager.shared.updateContext(sensitivity: level)
            }
        } else if payload["emergencyAlert"] == nil && payload["heartRate"] == nil && !foundHealthData {
            print("ℹ️ [WCM-iPhone] Unhandled payload: \(payload)")
        }

        // ─────────────────────────────────────────────────────────────────
        // Detection Pipeline — batch sensor routing
        //
        // The Watch sends a "sensorBatch" every 2 seconds containing ~100
        // [ax, ay, az, gx, gy, gz, timestamp] arrays collected at ~50 Hz.
        // HR is provided separately via "heartRate" (already extracted above).
        // ─────────────────────────────────────────────────────────────────
        if let batch = payload["sensorBatch"] as? [[Double]] {
            var samples: [SensorSample] = []
            samples.reserveCapacity(batch.count)
            for row in batch {
                guard row.count >= 7 else { continue }
                samples.append(SensorSample(
                    timestamp: row[6],
                    ax: row[0], ay: row[1], az: row[2],
                    gx: row[3], gy: row[4], gz: row[5],
                    hr: hrValue > 0 ? hrValue : nil
                ))
            }
            if !samples.isEmpty {
                print("🧠 [WCM-iPhone] Forwarding batch of \(samples.count) samples → SeizureDetectionManager")
                SeizureDetectionManager.shared.processBatch(samples)
                // Keep HR baseline context current
                if hrValue > 0 {
                    let motionSMA = samples.map { $0.accelMagnitude }.reduce(0, +) / Double(samples.count)
                    SeizureDetectionManager.shared.updateContext(latestHR: hrValue, latestMotionSMA: motionSMA)
                }
            }
        }
        // Backward-compatible single-sample path (pre-batch Watch builds)
        else if let ax = payload["ax"] as? Double,
                let ay = payload["ay"] as? Double,
                let az = payload["az"] as? Double,
                let timestamp = payload["timestamp"] as? Double {
            let sample = SensorSample(
                timestamp: timestamp,
                ax: ax,
                ay: ay,
                az: az,
                gx: payload["gx"] as? Double ?? 0,
                gy: payload["gy"] as? Double ?? 0,
                gz: payload["gz"] as? Double ?? 0,
                hr: hrValue > 0 ? hrValue : nil
            )

            print("🧠 Sending sample to SeizureDetectionManager")

            SeizureDetectionManager.shared.processSample(sample: sample)
        }
    }
}



