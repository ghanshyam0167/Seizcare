//
//  LocationManager.swift
//  Seizcare
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    //====================================================
    // MARK: - Core Operations
    //====================================================
    
    func requestAuthorization() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    //====================================================
    // MARK: - CLLocationManagerDelegate
    //====================================================
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.lastLocation = location
        NotificationCenter.default.post(name: NSNotification.Name("LocationUpdated"), object: nil)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager didFailWithError: \(error.localizedDescription)")
    }
    
    //====================================================
    // MARK: - Helpers
    //====================================================
    
    func getAppleMapsLink(latitude: Double, longitude: Double) -> String {
        return "https://maps.apple.com/?q=Emergency+Location&ll=\(latitude),\(longitude)"
    }
    
    func getCurrentAppleMapsLink() -> String? {
        guard let location = lastLocation else { return nil }
        return getAppleMapsLink(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
}
