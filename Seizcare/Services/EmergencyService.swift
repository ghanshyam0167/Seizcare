//
//  EmergencyService.swift
//  Seizcare
//
//  Handles the emergency alert workflow:
//  1. Fetches the current GPS location from LocationManager
//  2. Retrieves saved emergency contacts from EmergencyContactDataModel
//  3. POSTs to the Supabase Edge Function → Twilio sends SMS to all contacts
//

import Foundation
import UIKit
import CoreLocation

// nonisolated class declaration needed because the project uses
// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor — without this the URLSession
// completion handler and async dispatch calls would run under @MainActor
// and cause issues when called from background threads.
class EmergencyService {

    static let shared = EmergencyService()

    // MARK: - Constants
    private let endpointURL = URL(string: "https://rewuxzcdgivbwmakwjtc.supabase.co/functions/v1/send-emergency-alert")!
    private let anonKey     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJld3V4emNkZ2l2YndtYWt3anRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTQ2OTEsImV4cCI6MjA4ODc5MDY5MX0.kk1Mq-O6SfQ60TZagcp202cGqNB08ywUPWgxlFdiXp4"

    private init() {}

    // MARK: - Entry Points

    /// Entry point called by WatchConnectivityManager when the Watch sends an emergency.
    /// Fires the alert immediately — no countdown UI.
    func triggerWithCountdown() {
        print("🚀 [EmergencyService] Emergency triggered — sending alert immediately")
        sendAlert()
    }


    /// Directly sends the emergency alert without a countdown.
    /// Called after the countdown completes, or directly for testing.
    func sendAlert() {
        print("🚀 [EmergencyService] sendAlert() called")

        // Ensure location tracking is running
        LocationManager.shared.startUpdatingLocation()
        print("📍 [EmergencyService] Location manager started")

        if let location = LocationManager.shared.lastLocation {
            print("📍 [EmergencyService] Got immediate location: \("28.4595"), \("77.0266")")
            sendAlertWithLocation()
        } else {
            print("⚠️ [EmergencyService] No location yet — waiting 3s for GPS fix...")
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.sendAlertWithLocation()
            }
        }
    }

    // MARK: - Core Logic

    private func sendAlertWithLocation() {
        print("🔍 [EmergencyService] sendAlertWithLocation() — checking contacts & location")

        // --- Contacts ---
        let contacts = EmergencyContactDataModel.shared.getContactsForCurrentUser()
        let phoneNumbers = contacts.map { formatPhoneNumber($0.contactNumber) }
        print("👥 [EmergencyService] Contacts (formatted): \(phoneNumbers)")

        guard !phoneNumbers.isEmpty else {
            print("❌ [EmergencyService] ABORT — No emergency contacts saved. Add contacts in the app first.")
            return
        }

        // --- Location: use real GPS coordinates ---
        guard let location = LocationManager.shared.lastLocation else {
            print("❌ [EmergencyService] ABORT — GPS location still unavailable after retry. Cannot send alert without a real location.")
            return
        }

        let latitude  = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        print("📍 [EmergencyService] Using real GPS: lat=\(latitude) lon=\(longitude)")

        // --- Build request ---
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)",forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "latitude":  latitude,
            "longitude": longitude,
            "contacts":  phoneNumbers
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let bodyStr = String(data: request.httpBody!, encoding: .utf8) ?? "-"
            print("📤 [EmergencyService] POST \(endpointURL.absoluteString)")
            print("📤 [EmergencyService] Body: \(bodyStr)")
        } catch {
            print("❌ [EmergencyService] Failed to serialise body: \(error.localizedDescription)")
            return
        }

        // --- Fire ---
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [EmergencyService] Network error: \(error.localizedDescription)")
                return
            }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "(empty)"
            if statusCode == 200 || statusCode == 201 {
                print("✅ [EmergencyService] SUCCESS (\(statusCode)): \(body)")
            } else {
                print("⚠️ [EmergencyService] Response (\(statusCode)): \(body)")
            }
        }.resume()

        print("⏳ [EmergencyService] URLSession task started — waiting for response...")
    }
}
