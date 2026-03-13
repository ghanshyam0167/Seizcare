import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var healthData = HealthData()
    
    // Authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false)
            return
        }
        
        let readTypes: Set<HKObjectType> = [heartRateType, spo2Type, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit Authorization Error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(success)
                if success {
                    self.fetchAllData()
                }
            }
        }
    }
    
    func fetchAllData() {
        fetchLatestHeartRate()
        fetchLatestSpO2()
        fetchLatestSleepDuration()
    }
    
    // Fetch Data Methods
    func fetchLatestHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample, error == nil else { return }
            let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            DispatchQueue.main.async {
                self.healthData.heartRate = value
            }
        }
        healthStore.execute(query)
    }
    
    func fetchLatestSpO2() {
        guard let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: spo2Type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample, error == nil else { return }
            let value = sample.quantity.doubleValue(for: HKUnit.percent())
            DispatchQueue.main.async {
                self.healthData.spo2 = value * 100
            }
        }
        healthStore.execute(query)
    }
    
    func fetchLatestSleepDuration() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKCategorySample, error == nil else { return }
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            let hours = duration / 3600.0
            DispatchQueue.main.async {
                self.healthData.sleepDurationHours = hours
            }
        }
        healthStore.execute(query)
    }
}
