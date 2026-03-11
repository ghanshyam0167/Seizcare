import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    private init() {}
    
    //  Authorization
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                completion(false, NSError(domain: "com.seizcare.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not available on this device"]))
            }
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit Authorization Error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    //  Fetch Data Methods
    
    func fetchLatestHeartRate(completion: @escaping (Double?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching heart rate: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = sample.quantity.doubleValue(for: heartRateUnit)
            
            DispatchQueue.main.async {
                completion(value)
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchLatestSpO2(completion: @escaping (Double?) -> Void) {
        guard let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: spo2Type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
             if let error = error {
                print("Error fetching SpO2: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let percentUnit = HKUnit.percent()
            let value = sample.quantity.doubleValue(for: percentUnit)
            
            DispatchQueue.main.async {
                completion(value * 100) // Convert 0.98 to 98.0
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchLatestSleepDuration(completion: @escaping (Double?) -> Void) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        // Retrieve the most recent session
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching sleep analysis: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            guard let sample = samples?.first as? HKCategorySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            let hours = duration / 3600.0
            
            DispatchQueue.main.async {
                completion(hours)
            }
        }
        
        healthStore.execute(query)
    }
}
