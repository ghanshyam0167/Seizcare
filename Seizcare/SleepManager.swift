//
//  SleepManager.swift
//  Seizcare
//

import Foundation
import HealthKit
import Combine

extension Notification.Name {
    static let didReceiveSleepAverage = Notification.Name("didReceiveSleepAverage")
}

class SleepManager: ObservableObject {
    static let shared = SleepManager()
    
    @Published var monthlyAverageSleep: Double = 0.0
    private let healthStore = HealthKitManager.shared.healthStore
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        healthStore.requestAuthorization(toShare: nil, read: [sleepType]) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func fetchMonthlySleepAverage() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        // Use a rolling 30 days rather than strictly resetting on the 1st of the calendar month
        let startOfRollingMonth = calendar.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfRollingMonth, end: now, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("❌ Error fetching monthly sleep data: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                return
            }
            
            // Include ALL sleep states: asleep, asleepCore, asleepDeep, asleepREM, asleepUnspecified
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleep.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]
            
            let asleepSamples = samples.filter { asleepValues.contains($0.value) }
            
            // Group sleep samples by day to calculate nightly sleep totals
            var sleepPerDay: [Date: Double] = [:]
            
            print("📊 Monthly Sleep Data Analysis:")
            for sample in asleepSamples {
                let durationHours = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
                
                // Shift time forward by 12 hours so sleep spanning midnight groups into the day you wake up (Apple Health standard)
                let logicalNightDate = calendar.date(byAdding: .hour, value: 12, to: sample.startDate)!
                let day = calendar.startOfDay(for: logicalNightDate)
                
                // Debug log each sleep sample
                let stageName = self.sleepStageName(for: sample.value)
                print("   - Sample: \(stageName), Duration: \(String(format: "%.2f", durationHours)) hrs, Date: \(sample.startDate) -> Grouped to: \(day)")
                
                sleepPerDay[day, default: 0.0] += durationHours
            }
            
            let sortedDays = sleepPerDay.keys.sorted()
            for day in sortedDays {
                if let hours = sleepPerDay[day] {
                    print("🗓️ Nightly sleep total: Day \(calendar.component(.day, from: day)): \(String(format: "%.2f", hours)) hrs")
                }
            }
            
            let numberOfNights = Double(sleepPerDay.count)
            let totalSleepHours = sleepPerDay.values.reduce(0, +)
            
            // Calculate the monthly average sleep
            let average = numberOfNights > 0 ? (totalSleepHours / numberOfNights) : 0.0
            
            print("📊 Total nights with data: \(Int(numberOfNights))")
            print("📈 Final monthly average: \(String(format: "%.2f", average)) hrs")
            
            DispatchQueue.main.async {
                self.monthlyAverageSleep = average
                
                // Sync the daily history to Supabase/Database
                SleepDataModel.shared.syncSleepData(dailyTotals: sleepPerDay)
                
                // Broadcast for UIKit Dashboard
                print("📣 [SleepManager] Posting NotificationCenter broadcast: didReceiveSleepAverage")
                NotificationCenter.default.post(name: .didReceiveSleepAverage, object: nil, userInfo: ["average": average])
            }
        }
        
        healthStore.execute(query)
    }
    
    private func sleepStageName(for rawValue: Int) -> String {
        switch rawValue {
        case HKCategoryValueSleepAnalysis.inBed.rawValue: return "In Bed"
        case HKCategoryValueSleepAnalysis.asleep.rawValue: return "Asleep"
        case HKCategoryValueSleepAnalysis.awake.rawValue: return "Awake"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: return "Core"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return "Deep"
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return "REM"
        default: return "Unknown (\(rawValue))"
        }
    }
}
