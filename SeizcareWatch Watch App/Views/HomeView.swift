import SwiftUI
import HealthKit
import WatchKit

struct HomeView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedSensitivity = "Medium"
    @State private var showingAlertConfirmation = false
    
    let sensitivities = ["Low", "Medium", "High"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 1. Emergency Alert (Moved back to top)
                VStack(spacing: 4) {
                    Button(action: sendEmergencyAlert) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Send Alert")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .background(Color(red: 1.0, green: 0.35, blue: 0.35))
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    
                    if showingAlertConfirmation {
                        Text("Alert sent")
                            .font(.footnote)
                            .foregroundColor(.green)
                            .padding(.top, 2)
                            .transition(.opacity)
                    }
                }
                
                // 2. Live Heart Rate
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.footnote)
                        Text("Heart Rate")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    if let hr = healthKitManager.healthData.heartRate {
                        Text("\(Int(hr)) BPM")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(heartRateColor(hr))
                    } else {
                        Text("-- BPM")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 4)
                
                // 3. Sensitivity Selector
                VStack(spacing: 8) {
                    Text("Sensitivity")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 2) {
                        ForEach(sensitivities, id: \.self) { level in
                            Button(action: {
                                selectedSensitivity = level
                                WatchConnectivityManager.shared.sendSensitivity(level)
                            }) {
                                Text(level)
                                    .font(.system(size: 13, weight: selectedSensitivity == level ? .semibold : .regular))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .background(selectedSensitivity == level ? Color.green.opacity(0.3) : Color.gray.opacity(0.15))
                                    .foregroundColor(selectedSensitivity == level ? .green : .white)
                            }
                            .buttonStyle(.plain)
                            .cornerRadius(8)
                        }
                    }
                    
                    Text(sensitivityDescription(for: selectedSensitivity))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                
                // 4. Quick Glance
                VStack(spacing: 8) {
                    HStack {
                        Text("SpO₂")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let spo2 = healthKitManager.healthData.spo2 {
                            Text("\(Int(spo2))%")
                                .font(.footnote.bold())
                                .foregroundColor(.secondary)
                        } else {
                            Text("--%")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Sleep")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let sleep = healthKitManager.healthData.sleepDurationHours {
                            Text(String(format: "%.1f hr", sleep))
                                .font(.footnote.bold())
                                .foregroundColor(.secondary)
                        } else {
                            Text("-- hr")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            healthKitManager.requestAuthorization { success in
                // Handled in completion
            }
        }
    }
    
    private func sendEmergencyAlert() {
        WKInterfaceDevice.current().play(.notification)
        WatchConnectivityManager.shared.sendEmergencyAlert()
        
        withAnimation {
            showingAlertConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showingAlertConfirmation = false
            }
        }
    }
    
    private func heartRateColor(_ hr: Double) -> Color {
        if hr < 60 || hr > 100 {
            return .red
        } else if hr >= 85 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func sensitivityDescription(for level: String) -> String {
        switch level {
        case "Low":
            return "Triggers alerts only for strong seizure patterns"
        case "Medium":
            return "Balanced detection for everyday use"
        case "High":
            return "Highly sensitive, detects even mild activity"
        default:
            return ""
        }
    }
}

#Preview {
    HomeView()
}
