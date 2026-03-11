import Foundation
import WatchConnectivity

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
            print("WatchConnectivity Watch activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WatchConnectivity Watch activated with state: \(activationState.rawValue)")
        print("Companion App Installed (iPhone): \(WCSession.default.isCompanionAppInstalled)")
    }
    
    func sendMessage(_ message: [String: Any]) {
        guard WCSession.default.activationState == .activated else {
            print("WCSession is not activated. Cannot send message.")
            return
        }
        
        guard WCSession.default.isCompanionAppInstalled else {
            print("WCSession counterpart (iPhone app) is NOT installed.")
            return
        }
        
        guard WCSession.default.isReachable else {
            print("WCSession is not reachable. iPhone app might not be running or reachable.")
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    func sendHeartRate(_ value: Double) {
        let message = ["heartRate": value]
        sendMessage(message)
    }
}
