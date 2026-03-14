import Foundation
import HealthKit
import Combine

class HealthKitManager: NSObject, ObservableObject {
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
    
    // Workout session properties for continuous background streaming
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    var workoutSessionActive: Bool {
        return workoutSession != nil
    }
    
    override init() {
        super.init()
    }
    
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
        let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            if let error = error {
                print("HealthKit Authorization Error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(success)
                if success {
                    self.fetchAllData()
                    self.startWorkout() // Trigger continuous streaming
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
    
    // MARK: - Continuous Heart Rate Collection (Workout Session)
    
    func startWorkout() {
        guard workoutSession == nil else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            builder?.delegate = self
            
            // Set data source for the builder
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { success, error in
                if success {
                    print("🏃‍♂️ [HKM-Watch] Workout session started. Continuous collection active.")
                } else if let error = error {
                    print("❌ [HKM-Watch] Failed to start collection: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ [HKM-Watch] Error starting workout session: \(error.localizedDescription)")
        }
    }
    
    func stopWorkout() {
        workoutSession?.end()
        builder?.endCollection(withEnd: Date()) { success, error in
            print("🛑 [HKM-Watch] Workout session ended.")
            self.workoutSession = nil
            self.builder = nil
        }
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

// MARK: - HKWorkoutSessionDelegate & HKLiveWorkoutBuilderDelegate

extension HealthKitManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("⚡️ [HKM-Watch] Workout session changed state: \(fromState.rawValue) → \(toState.rawValue)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ [HKM-Watch] Workout session failed: \(error.localizedDescription)")
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        if collectedTypes.contains(heartRateType) {
            let statistics = workoutBuilder.statistics(for: heartRateType)
            if let quantity = statistics?.mostRecentQuantity() {
                let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                DispatchQueue.main.async {
                    print("💓 [HKM-Watch] Live Heart Rate: \(Int(bpm)) BPM")
                    self.healthData.heartRate = bpm
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle events if needed
    }
}
