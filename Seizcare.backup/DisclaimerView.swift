import SwiftUI

struct DisclaimerView: View {
    // Action closure to handle navigation callback
    var onUnderstandTapped: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // 1. Warning Icon with styling
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 40)
                
                // 2. Title
                Text("Important Medical Notice")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                // 3. Disclaimer Card
                VStack(spacing: 16) {
                    Text("This application is designed to monitor data and alert contacts based on physiological changes. It is not a medical device and is not intended to diagnose, treat, cure, or prevent any medical condition.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 0.7, green: 0.1, blue: 0.0))
                        .lineSpacing(4)
                }
                .padding(20)
                .background(Color(red: 1.0, green: 0.95, blue: 0.93))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                
                // 4. "How We Help" Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("How We Help:")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("We log detailed seizure data (duration, time, vitals) to provide comprehensive reports for your doctor, improving communication and care.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 20)
                
                // 5. Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onUnderstandTapped()
                    }
                }) {
                    Text("I Understand")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemBackground))
    }
}

// Custom button style for scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct DisclaimerView_Previews: PreviewProvider {
    static var previews: some View {
        DisclaimerView(onUnderstandTapped: {})
    }
}
