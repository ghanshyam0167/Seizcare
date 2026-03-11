//
//  ContentView.swift
//  SeizcareWatch Watch App
//
//  Created by Diya Sharma on 11/03/26.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var healthStore = HKHealthStore()
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .imageScale(.large)
                .foregroundStyle(.red)
            
            Text("Seizcare Watch")
            
            Button("Send Heart Rate") {
                fetchAndSendHeartRate()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .onAppear {
            requestHealthKitAuthorization()
        }
    }
    
    private func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
            if let error = error {
                print("HK Authorization failing: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchAndSendHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error reading HR: \(error.localizedDescription)")
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No HR sample found.")
                return
            }
            
            let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = sample.quantity.doubleValue(for: hrUnit)
            
            WatchConnectivityManager.shared.sendHeartRate(value)
        }
        
        healthStore.execute(query)
    }
}

#Preview {
    ContentView()
}
