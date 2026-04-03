import SwiftUI

struct RecordsView: View {
    @StateObject private var viewModel = RecordsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Health Records")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                if !viewModel.isAuthorized {
                    Text("Please authorize Health access to view your records.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    
                    // Heart Rate
                    let hrValue = viewModel.heartRate != nil ? "\(Int(viewModel.heartRate!))" : "--"
                    MetricCard(title: "Heart Rate", value: hrValue, unit: "BPM", icon: "heart.fill", color: .red)
                    
                    // SpO2
                    let spo2Value = viewModel.oxygenSaturation != nil ? String(format: "%.1f", viewModel.oxygenSaturation!) : "--"
                    MetricCard(title: "SpO2", value: spo2Value, unit: "%", icon: "lungs.fill", color: .blue)
                    
                    // Sleep
                    let sleepValue = viewModel.sleepDuration != nil ? String(format: "%.1f", viewModel.sleepDuration!) : "--"
                    MetricCard(title: "Sleep", value: sleepValue, unit: "hrs", icon: "bed.double.fill", color: .purple)
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.requestAuthorization()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RecordsView_Previews: PreviewProvider {
    static var previews: some View {
        RecordsView()
    }
}
