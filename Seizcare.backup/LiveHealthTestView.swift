import SwiftUI

struct LiveHealthTestView: View {
    @StateObject private var wcm = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "applewatch")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text("Watch Connectivity Test")
                .font(.title2.bold())
            
            VStack(spacing: 24) {
                // Heart Rate
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Heart Rate")
                        .fontWeight(.semibold)
                    Spacer()
                    if let hr = wcm.heartRate {
                        Text("\(Int(hr)) BPM")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    } else {
                        Text("-- BPM")
                            .foregroundColor(.gray)
                    }
                }
                
                // SpO2
                HStack {
                    Image(systemName: "lungs.fill")
                        .foregroundColor(.cyan)
                    Text("SpO₂")
                        .fontWeight(.semibold)
                    Spacer()
                    if let spo2 = wcm.spo2 {
                        Text("\(Int(spo2))%")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    } else {
                        Text("-- %")
                            .foregroundColor(.gray)
                    }
                }
                
                // Sleep
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.indigo)
                    Text("Sleep")
                        .fontWeight(.semibold)
                    Spacer()
                    if let sleep = wcm.sleepHours {
                        Text(String(format: "%.1f Hrs", sleep))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    } else {
                        Text("-- Hrs")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(24)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Test Button
            Button(action: {
                print("🕹️ [Test] Manually triggering sleep average fetch & sync...")
                SleepManager.shared.fetchMonthlySleepAverage()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.icloud.fill")
                    Text("Fetch & Sync Sleep")
                }
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Text("Ensure the Watch Simulator is running and Health data permissions are granted.")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                
            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    LiveHealthTestView()
}
