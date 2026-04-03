//
//  DashboardView.swift
//  Seizcare
//

import SwiftUI

struct DashboardView: View {
    // Observe the SleepManager for monthly average updates
    @StateObject private var sleepManager = SleepManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Monthly Sleep Quality Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.indigo)
                        Text("Sleep Quality")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if sleepManager.monthlyAverageSleep > 0 {
                        Text("\(String(format: "%.1f", sleepManager.monthlyAverageSleep)) hrs avg")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text("No sleep data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .onChange(of: sleepManager.monthlyAverageSleep) { newValue in
                    print("✅ [DashboardView] Monthly average updated: \(String(format: "%.1f", newValue)) hrs")
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .onAppear {
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    sleepManager.fetchMonthlySleepAverage()
                } else if let error = error {
                    print("❌ Auth failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
