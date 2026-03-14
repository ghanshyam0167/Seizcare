import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var healthData = HealthData() {
        didSet {
            print("📝 [HKM-Watch] HealthKit Data updated → HR: \(healthData.heartRate ?? 0), SpO2: \(healthData.spo2 ?? 0), Sleep: \(healthData.sleepDurationHours ?? 0)")
            WatchConnectivityManager.shared.sendHealthData(
                heartRate: healthData.heartRate,
                spo2: healthData.spo2,
                sleepHours: healthData.sleepDurationHours
            )
        }
    }
    
    private var heartRateAnchor: HKQueryAnchor?
    private var isStreaming = false
    private var spo2Timer: Timer?
    
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
                    self.startLiveHeartRateStreaming()
                    self.startPeriodicSpO2Fetching()
                }
            }
        }
    }
    
    func fetchAllData() {
        fetchLatestHeartRate()
        fetchLatestSpO2()
        fetchLatestSleepDuration()
    }
    
    // Stream live heart rate
    func startLiveHeartRateStreaming() {
        guard !isStreaming else { return }
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        isStreaming = true
        
        // Query for samples from now onwards
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] query, addedSamples, deletedSamples, newAnchor, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Heart rate anchored object query error: \(error.localizedDescription)")
                return
            }
            
            self.heartRateAnchor = newAnchor
            
            if let samples = addedSamples as? [HKQuantitySample], let latestSample = samples.last {
                let value = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                DispatchQueue.main.async {
                    self.healthData.heartRate = value
                }
            }
        }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: heartRateAnchor, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    // Periodic SpO2 Fetching
    func startPeriodicSpO2Fetching() {
        spo2Timer?.invalidate()
        spo2Timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchLatestSpO2()
        }
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
        
        let now = Date()
        let calendar = Calendar.current
        
        // Define "last night": Start = yesterday 6:00 PM, End = now
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let startDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday) else { return }
        let endDate = now
        
        print("🛌 [HKM-Watch] Querying sleep from \(startDate) to \(endDate)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("❌ [HKM-Watch] Error fetching sleep data: \(error.localizedDescription)")
                return
            }
            
            guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                print("🛌 [HKM-Watch] No sleep samples found for the specified period.")
                DispatchQueue.main.async {
                    self.healthData.sleepDurationHours = 0.0
                }
                return
            }
            
            // Filter only for .asleep (this combines .asleepUnspecified, .asleepDeep, .asleepCore, .asleepREM in older/newer APIs)
            // or we specifically exclude .inBed and .awake
            let asleepSamples = categorySamples.filter { sample in
                let value = sample.value
                return value != HKCategoryValueSleepAnalysis.inBed.rawValue && 
                       value != HKCategoryValueSleepAnalysis.awake.rawValue
            }
            
            let totalDuration = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let hours = totalDuration / 3600.0
            
            print("📊 [HKM-Watch] Calculated sleep: \(String(format: "%.1f", hours)) hours from \(asleepSamples.count) asleep samples")
            
            DispatchQueue.main.async {
                self.healthData.sleepDurationHours = hours
            }
        }
        healthStore.execute(query)
    }
}
