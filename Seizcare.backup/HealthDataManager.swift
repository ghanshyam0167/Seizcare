//
//  HealthDataManager.swift
//  Seizcare
//

import Foundation
import Combine

class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()
    
    @Published var sleepHours: Double = 0.0
    
    private init() {}
    
    func updateSleepData(hours: Double) {
        // Update local Published property on main thread for UI
        DispatchQueue.main.async {
            self.sleepHours = hours
            print("🔄 [HealthDataManager] Updated sleepHours: \(String(format: "%.1f", hours)) hrs")
        }
        
        // Save to Supabase and local cache
        SleepDataModel.shared.addSleepEntry(date: Date(), hours: hours)
    }
}
