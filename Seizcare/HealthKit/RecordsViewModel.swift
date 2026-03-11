import Foundation
import Combine

class RecordsViewModel: ObservableObject {
    @Published var heartRate: Double?
    @Published var oxygenSaturation: Double?
    @Published var sleepDuration: Double?
    @Published var isAuthorized: Bool = false
    
    private let healthKitManager = HealthKitManager.shared
    
    init() {
        // Authorization is now triggered from the view
    }
    
    func requestAuthorization() {
        healthKitManager.requestAuthorization { [weak self] success, error in
            self?.isAuthorized = success
            if success {
                self?.fetchAllData()
            } else {
                print("HealthKit Authorization failed: \(String(describing: error))")
            }
        }
    }
    
    func fetchAllData() {
        healthKitManager.fetchLatestHeartRate { [weak self] value in
            self?.heartRate = value
        }
        
        healthKitManager.fetchLatestSpO2 { [weak self] value in
            self?.oxygenSaturation = value
        }
        
        healthKitManager.fetchLatestSleepDuration { [weak self] value in
            self?.sleepDuration = value
        }
    }
}
