import Foundation
import WatchConnectivity
import os

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate Method
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WatchConnectivity iPhone activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WatchConnectivity iPhone activated with state: \(activationState.rawValue)")
        print("Watch App Installed: \(WCSession.default.isWatchAppInstalled)")
        if WCSession.default.isWatchAppInstalled {
            print("Watch App is paired and installed on Apple Watch.")
        } else {
            print("No Apple Watch paired or Watch App is not installed.")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WatchConnectivity iPhone session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WatchConnectivity iPhone session did deactivate")
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["heartRate"] as? Double {
                print("Heart Rate received from watch: \(Int(heartRate)) bpm")
            } else {
                print("Received message from Watch: \(message)")
            }
        }
    }
}
